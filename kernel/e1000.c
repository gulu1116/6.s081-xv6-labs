#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "e1000_dev.h"
#include "net.h"

#define TX_RING_SIZE 16
static struct tx_desc tx_ring[TX_RING_SIZE] __attribute__((aligned(16)));
static struct mbuf *tx_mbufs[TX_RING_SIZE];

#define RX_RING_SIZE 16
static struct rx_desc rx_ring[RX_RING_SIZE] __attribute__((aligned(16)));
static struct mbuf *rx_mbufs[RX_RING_SIZE];

// remember where the e1000's registers live.
static volatile uint32 *regs;

struct spinlock e1000_lock;

// called by pci_init().
// xregs is the memory address at which the
// e1000's registers are mapped.
void
e1000_init(uint32 *xregs)
{
  int i;

  initlock(&e1000_lock, "e1000");

  regs = xregs;

  // Reset the device
  regs[E1000_IMS] = 0; // disable interrupts
  regs[E1000_CTL] |= E1000_CTL_RST;
  regs[E1000_IMS] = 0; // redisable interrupts
  __sync_synchronize();

  // [E1000 14.5] Transmit initialization
  memset(tx_ring, 0, sizeof(tx_ring));
  for (i = 0; i < TX_RING_SIZE; i++) {
    tx_ring[i].status = E1000_TXD_STAT_DD;
    tx_mbufs[i] = 0;
  }
  regs[E1000_TDBAL] = (uint64) tx_ring;
  if(sizeof(tx_ring) % 128 != 0)
    panic("e1000");
  regs[E1000_TDLEN] = sizeof(tx_ring);
  regs[E1000_TDH] = regs[E1000_TDT] = 0;
  
  // [E1000 14.4] Receive initialization
  memset(rx_ring, 0, sizeof(rx_ring));
  for (i = 0; i < RX_RING_SIZE; i++) {
    rx_mbufs[i] = mbufalloc(0);
    if (!rx_mbufs[i])
      panic("e1000");
    rx_ring[i].addr = (uint64) rx_mbufs[i]->head;
  }
  regs[E1000_RDBAL] = (uint64) rx_ring;
  if(sizeof(rx_ring) % 128 != 0)
    panic("e1000");
  regs[E1000_RDH] = 0;
  regs[E1000_RDT] = RX_RING_SIZE - 1;
  regs[E1000_RDLEN] = sizeof(rx_ring);

  // filter by qemu's MAC address, 52:54:00:12:34:56
  regs[E1000_RA] = 0x12005452;
  regs[E1000_RA+1] = 0x5634 | (1<<31);
  // multicast table
  for (int i = 0; i < 4096/32; i++)
    regs[E1000_MTA + i] = 0;

  // transmitter control bits.
  regs[E1000_TCTL] = E1000_TCTL_EN |  // enable
    E1000_TCTL_PSP |                  // pad short packets
    (0x10 << E1000_TCTL_CT_SHIFT) |   // collision stuff
    (0x40 << E1000_TCTL_COLD_SHIFT);
  regs[E1000_TIPG] = 10 | (8<<10) | (6<<20); // inter-pkt gap

  // receiver control bits.
  regs[E1000_RCTL] = E1000_RCTL_EN | // enable receiver
    E1000_RCTL_BAM |                 // enable broadcast
    E1000_RCTL_SZ_2048 |             // 2048-byte rx buffers
    E1000_RCTL_SECRC;                // strip CRC
  
  // ask e1000 for receive interrupts.
  regs[E1000_RDTR] = 0; // interrupt after every received packet (no timer)
  regs[E1000_RADV] = 0; // interrupt after every packet (no timer)
  regs[E1000_IMS] = (1 << 7); // RXDW -- Receiver Descriptor Write Back
}

int
e1000_transmit(struct mbuf *m)
{
  uint32 tdt;
  // 并发安全，保护对环和寄存器的访问
  acquire(&e1000_lock);

  // 1) 读网卡期望的下一个 TX 索引（TDT）
  tdt = regs[E1000_TDT];

  // 2) 检查对应的描述符是否已完成（DD = 1），如果没有，说明环已满
  if (!(tx_ring[tdt].status & E1000_TXD_STAT_DD)) {
    // 无可用描述符：失败，调用者会释放 mbuf
    release(&e1000_lock);
    return -1;
  }

  // 3) 如果该槽之前保存了一个 mbuf，说明之前发送已完成，但尚未释放，释放它
  if (tx_mbufs[tdt]) {
    mbuffree(tx_mbufs[tdt]);
    tx_mbufs[tdt] = 0;
  }

  // 4) 填充描述符：地址、长度、cmd
  //    m->head 指向包数据，m->len 是长度
  tx_ring[tdt].addr = (uint64) m->head;
  tx_ring[tdt].length = m->len;

  // 设置需要的命令位（要求报告完成 RS；包结束 EOP）
  tx_ring[tdt].cmd = E1000_TXD_CMD_RS | E1000_TXD_CMD_EOP;

  // 清除 status（网卡会在完成后写回 DD）
  tx_ring[tdt].status = 0;

  // 保存 mbuf 指针，稍后网卡驱动在 descriptor DD 置位时会释放
  tx_mbufs[tdt] = m;

  // 5) 更新 TDT，通知网卡新的尾索引（取模 TX_RING_SIZE）
  regs[E1000_TDT] = (tdt + 1) % TX_RING_SIZE;

  // 6) 内存屏障（确保对描述符的写在写 TDT 之前完成）
  __sync_synchronize();

  release(&e1000_lock);
  return 0;
}

static void
e1000_recv(void)
{
  acquire(&e1000_lock);

  // 循环处理所有已到达、还未处理的描述符
  while (1) {
    // 网卡的 RDT 指向最后一个驱动通知给网卡的已空 descriptor。
    // 下一个有数据（如果有）的 descriptor 索引是 RDT + 1 (mod RX_RING_SIZE)
    uint32 rdt = (regs[E1000_RDT] + 1) % RX_RING_SIZE;

    // 检查该描述符是否已由网卡写入完（DD）
    if (!(rx_ring[rdt].status & E1000_RXD_STAT_DD)) {
      // 没有更多接收包
      break;
    }

    // 取出对应的 mbuf，设置长度，由网卡写回的 length 字段给出
    struct mbuf *m = rx_mbufs[rdt];
    if (!m) {
      // 不应该发生：如果没有 mbuf 就 panic
      panic("e1000_recv: missing mbuf");
    }

    // rx descriptor 的 length 字段包含接收到的包长
    m->len = rx_ring[rdt].length;

    // 为该 slot 分配一个新的 mbuf 以供网卡下次接收使用
    struct mbuf *newm = mbufalloc(0);
    if (!newm) {
      // 分配失败：无法继续接收。为了安全起见 panic（也可以 free 原 mbuf 并退出循环）
      panic("e1000_recv: mbufalloc failed");
    }

    // 把新的 mbuf 放回 descriptor，并清除 status
    rx_mbufs[rdt] = newm;
    rx_ring[rdt].addr = (uint64)newm->head;
    rx_ring[rdt].status = 0;

    // 更新 RDT 为刚刚处理的这个索引，告诉网卡这个 descriptor 已经可用
    regs[E1000_RDT] = rdt;

    // 内存屏障，确保写回 RDT 在前面的 descriptor 写完成后对网卡可见
    __sync_synchronize();

    // 先释放锁再把包提交给网络栈（net_rx 可能会产生调度/阻塞）
    release(&e1000_lock);
    net_rx(m);
    // 处理完后重新获取锁，继续循环处理更多包
    acquire(&e1000_lock);
  }

  release(&e1000_lock);
}

void
e1000_intr(void)
{
  // tell the e1000 we've seen this interrupt;
  // without this the e1000 won't raise any
  // further interrupts.
  regs[E1000_ICR] = 0xffffffff;

  e1000_recv();
}
