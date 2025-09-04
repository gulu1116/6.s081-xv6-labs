#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "proc.h"
#include "defs.h"
#include "fs.h"
#include "file.h"
#include "fcntl.h" // 需要包含这些头文件以使用文件相关函数

struct spinlock tickslock;
uint ticks;

extern char trampoline[], uservec[], userret[];

// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

void
trapinit(void)
{
  initlock(&tickslock, "time");
}

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}

//
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
//
void
usertrap(void)
{
  int which_dev = 0;

  if((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // send interrupts and exceptions to kerneltrap(),
  // since we're now in the kernel.
  w_stvec((uint64)kernelvec);

  struct proc *p = myproc();
  
  // save user program counter.
  p->trapframe->epc = r_sepc();
  
  if(r_scause() == 8){
    // system call

    if(p->killed)
      exit(-1);

    // sepc points to the ecall instruction,
    // but we want to return to the next instruction.
    p->trapframe->epc += 4;

    // an interrupt will change sstatus &c registers,
    // so don't enable until done with those registers.
    intr_on();

    syscall();
  } else if((which_dev = devintr()) != 0){
    // ok
  } else {
    // 处理其他异常，主要是缺页异常
    uint64 va = r_stval(); // 获取引发缺页的虚拟地址

    // 关键：检查缺页地址是否可能属于一个 mmap 区域
    if (va >= p->sz || va < p->trapframe->sp) {
      // 地址超出进程大小或低于栈顶，是非法访问
      p->killed = 1;
      goto end;
    }

    // 将对齐到页面起始地址
    va = PGROUNDDOWN(va);

    // 遍历进程的所有 VMA，检查 va 是否落在某个 VMA 区间内
    struct vma *vma = 0;
    for (int i = 0; i < NVMA; i++) {
      if (p->vmas[i].used &&
          va >= p->vmas[i].addr &&
          va < p->vmas[i].addr + p->vmas[i].length) {
        vma = &p->vmas[i];
        break;
      }
    }

    if (vma == 0) {
      // 该地址不属于任何 mmap 区域，是非法访问
      p->killed = 1;
      goto end;
    }

    // 现在我们知道这是一个合法的 mmap 缺页
    // 1. 分配一个物理页
    char *mem = kalloc();
    if(mem == 0){
      p->killed = 1; // 内存分配失败，杀死进程
      goto end;
    }
    memset(mem, 0, PGSIZE); // 清零新页面（可选，但更安全）

    // 2. 计算文件中需要读取的偏移量
    //    va 在 VMA 中的偏移 = va - vma->addr
    //    文件中的偏移 = vma->offset + (va - vma->addr)
    uint64 file_offset = vma->offset + (va - vma->addr);
    
    // 3. 将文件内容读取到新分配的物理页
    ilock(vma->file->ip);
    int read_bytes = readi(vma->file->ip, 0, (uint64)mem, file_offset, PGSIZE);
    iunlock(vma->file->ip);

    if(read_bytes < 0){
      // 文件读取失败，清理并杀死进程
      kfree(mem);
      p->killed = 1;
      goto end;
    }
    // 如果 read_bytes < PGSIZE，页面剩余部分已经是零（因为memset）

    // 4. 根据 VMA 的权限设置 PTE 的标志位
    int pte_flags = PTE_U; // 用户模式可访问是必须的
    if(vma->prot & PROT_READ)  pte_flags |= PTE_R;
    if(vma->prot & PROT_WRITE) pte_flags |= PTE_W;
    if(vma->prot & PROT_EXEC)  pte_flags |= PTE_X;
    // 注意：即使 VMA 可写，文件也可能以只读打开。
    // 但对于 MAP_PRIVATE，我们仍然需要在 PTE 中保留可写权限以供进程修改私有副本。
    // 我们的参数检查已经确保了 MAP_SHARED 且 PROT_WRITE 时文件是可写的。

    // 5. 将物理页映射到用户的页表中
    if(mappages(p->pagetable, va, PGSIZE, (uint64)mem, pte_flags) != 0){
      // 映射失败（例如页表分配失败），清理并杀死进程
      kfree(mem);
      p->killed = 1;
    }

  end:
    ;
  }

  if(p->killed)
    exit(-1);

  // give up the CPU if this is a timer interrupt.
  if(which_dev == 2)
    yield();

  usertrapret();
}

//
// return to user space
//
void
usertrapret(void)
{
  struct proc *p = myproc();

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
  p->trapframe->kernel_trap = (uint64)usertrap;
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()

  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
  x |= SSTATUS_SPIE; // enable interrupts in user mode
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
}

// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
void 
kerneltrap()
{
  int which_dev = 0;
  uint64 sepc = r_sepc();
  uint64 sstatus = r_sstatus();
  uint64 scause = r_scause();
  
  if((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  if(intr_get() != 0)
    panic("kerneltrap: interrupts enabled");

  if((which_dev = devintr()) == 0){
    printf("scause %p\n", scause);
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // give up the CPU if this is a timer interrupt.
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    yield();

  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void
clockintr()
{
  acquire(&tickslock);
  ticks++;
  wakeup(&ticks);
  release(&tickslock);
}

// check if it's an external interrupt or software interrupt,
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
     (scause & 0xff) == 9){
    // this is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
    int irq = plic_claim();

    if(irq == UART0_IRQ){
      uartintr();
    } else if(irq == VIRTIO0_IRQ){
      virtio_disk_intr();
    } else if(irq){
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // the PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    // software interrupt from a machine-mode timer interrupt,
    // forwarded by timervec in kernelvec.S.

    if(cpuid() == 0){
      clockintr();
    }
    
    // acknowledge the software interrupt by clearing
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
  }
}

