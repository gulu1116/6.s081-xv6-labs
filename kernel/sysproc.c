#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if(argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;
  struct proc *p = myproc(); // 获取当前进程

  if(argint(0, &n) < 0)
    return -1;
  addr = p->sz; // 保存旧的进程大小

  // 删除原有的 growproc() 调用
  // if(growproc(n) < 0)
  //   return -1;

  if (n > 0) {
    // 延迟分配：只增加进程的虚拟地址空间大小
    p->sz += n;
  } else if (p->sz + n > 0) {
    // 如果 n 是负数，且收缩后大小仍大于0，则立即释放内存
    p->sz = uvmdealloc(p->pagetable, p->sz, p->sz + n);
  } else {
    // 如果收缩到小于0，则返回错误
    return -1;
  }
  return addr; // 返回旧的进程大小
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}
