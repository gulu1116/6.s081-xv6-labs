//
// File-system system calls.
// Mostly argument checking, since we don't trust
// user code, and calls into file.c and fs.c.
//

#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "stat.h"
#include "spinlock.h"
#include "proc.h"
#include "fs.h"
#include "sleeplock.h"
#include "file.h"
#include "fcntl.h"

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    return -1;
  if(pfd)
    *pfd = fd;
  if(pf)
    *pf = f;
  return 0;
}

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
  int fd;
  struct proc *p = myproc();

  for(fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd] == 0){
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
}

uint64
sys_dup(void)
{
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    return -1;
  if((fd=fdalloc(f)) < 0)
    return -1;
  filedup(f);
  return fd;
}

uint64
sys_read(void)
{
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    return -1;
  return fileread(f, p, n);
}

uint64
sys_write(void)
{
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    return -1;

  return filewrite(f, p, n);
}

uint64
sys_close(void)
{
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    return -1;
  myproc()->ofile[fd] = 0;
  fileclose(f);
  return 0;
}

uint64
sys_fstat(void)
{
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    return -1;
  return filestat(f, st);
}

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    return -1;

  begin_op();
  if((ip = namei(old)) == 0){
    end_op();
    return -1;
  }

  ilock(ip);
  if(ip->type == T_DIR){
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
  ilock(dp);
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
  iput(ip);

  end_op();

  return 0;

bad:
  ilock(ip);
  ip->nlink--;
  iupdate(ip);
  iunlockput(ip);
  end_op();
  return -1;
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
}

uint64
sys_unlink(void)
{
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    return -1;

  begin_op();
  if((dp = nameiparent(path, name)) == 0){
    end_op();
    return -1;
  }

  ilock(dp);

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
  ilock(ip);

  if(ip->nlink < 1)
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    panic("unlink: writei");
  if(ip->type == T_DIR){
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);

  ip->nlink--;
  iupdate(ip);
  iunlockput(ip);

  end_op();

  return 0;

bad:
  iunlockput(dp);
  end_op();
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    return 0;

  ilock(dp);

  if((ip = dirlookup(dp, name, 0)) != 0){
    iunlockput(dp);
    ilock(ip);
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
      return ip;
    iunlockput(ip);
    return 0;
  }

  if((ip = ialloc(dp->dev, type)) == 0)
    panic("create: ialloc");

  ilock(ip);
  ip->major = major;
  ip->minor = minor;
  ip->nlink = 1;
  iupdate(ip);

  if(type == T_DIR){  // Create . and .. entries.
    dp->nlink++;  // for ".."
    iupdate(dp);
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
      panic("create dots");
  }

  if(dirlink(dp, name, ip->inum) < 0)
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}

uint64
sys_open(void)
{
  char path[MAXPATH];
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    return -1;

  begin_op();

  if(omode & O_CREATE){
    ip = create(path, T_FILE, 0, 0);
    if(ip == 0){
      end_op();
      return -1;
    }
  } else {
    if((ip = namei(path)) == 0){
      end_op();
      return -1;
    }
    ilock(ip);
    if(ip->type == T_DIR && omode != O_RDONLY){
      iunlockput(ip);
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    if(f)
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    f->off = 0;
  }
  f->ip = ip;
  f->readable = !(omode & O_WRONLY);
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);

  if((omode & O_TRUNC) && ip->type == T_FILE){
    itrunc(ip);
  }

  iunlock(ip);
  end_op();

  return fd;
}

uint64
sys_mkdir(void)
{
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    end_op();
    return -1;
  }
  iunlockput(ip);
  end_op();
  return 0;
}

uint64
sys_mknod(void)
{
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
  if((argstr(0, path, MAXPATH)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    end_op();
    return -1;
  }
  iunlockput(ip);
  end_op();
  return 0;
}

uint64
sys_chdir(void)
{
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
  
  begin_op();
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    end_op();
    return -1;
  }
  ilock(ip);
  if(ip->type != T_DIR){
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
  iput(p->cwd);
  end_op();
  p->cwd = ip;
  return 0;
}

uint64
sys_exec(void)
{
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
    if(i >= NELEM(argv)){
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
      goto bad;
    }
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    if(argv[i] == 0)
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
      goto bad;
  }

  int ret = exec(path, argv);

  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    kfree(argv[i]);
  return -1;
}

uint64
sys_pipe(void)
{
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();

  if(argaddr(0, &fdarray) < 0)
    return -1;
  if(pipealloc(&rf, &wf) < 0)
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    if(fd0 >= 0)
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    p->ofile[fd0] = 0;
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
}

// kernel/sysfile.c
#include "fcntl.h" // 确保包含了这个头文件以使用 PROT_READ 等常量

uint64
sys_mmap(void)
{
  // 1. 从陷阱帧中获取系统调用参数
  uint64 addr;
  int length, prot, flags, fd, offset;
  struct file *f;

  // 使用 arg* 函数读取参数
  if(argaddr(0, &addr) < 0 || argint(1, &length) < 0 ||
     argint(2, &prot) < 0 || argint(3, &flags) < 0 ||
     argfd(4, &fd, &f) < 0 || argint(5, &offset) < 0)
    return -1;

  // 2. 参数合法性检查
  if (length <= 0) return -1;
  // 检查 prot 是否包含有效组合
  if ((prot & (PROT_READ | PROT_WRITE | PROT_EXEC)) == 0) return -1;
  // 如果要求 PROT_WRITE 且是 MAP_SHARED，但文件本身不可写，则错误
  if ((prot & PROT_WRITE) && (flags & MAP_SHARED) && !f->writable) return -1;
  // 如果要求 PROT_READ，但文件不可读，则错误
  if ((prot & PROT_READ) && !f->readable) return -1;
  // 检查文件偏移量是否页面对齐（简化实现）
  if (offset % PGSIZE != 0) return -1;

  struct proc *p = myproc();
  // 将长度向上取整到页面大小
  length = PGROUNDUP(length);

  // 3. 检查进程地址空间是否会超出限制
  // 我们选择从当前进程大小 p->sz 开始映射（addr=0 的常见情况）
  uint64 proposed_addr = (addr == 0) ? p->sz : addr;
  if (proposed_addr + length > MAXVA) {
    return -1;
  }

  // 4. 在进程的 vmas 数组中找到一个空闲的槽位
  struct vma *vv = 0;
  for (int i = 0; i < NVMA; i++) {
    if (p->vmas[i].used == 0) {
      vv = &p->vmas[i];
      break;
    }
  }
  if (vv == 0) {
    return -1; // 没有空闲的 VMA 槽位
  }

  // 5. 填充找到的 VMA 结构
  vv->used = 1;
  vv->addr = proposed_addr; // 映射的起始地址
  vv->length = length;      // 映射的长度
  vv->prot = prot;          // 权限
  vv->flags = flags;        // 标志
  vv->file = f;             // 文件指针
  vv->offset = offset;      // 文件偏移

  // 6. 增加文件的引用计数，防止文件在映射时被关闭
  filedup(f);

  // 7. 如果用户没有指定地址（addr=0），我们更新进程的大小 p->sz
  //    这样后续的 mmap 或 sbrk 就会从新的地址开始。
  if (addr == 0) {
    p->sz = proposed_addr + length;
  }

  // 8. 返回映射区域的起始地址
  return proposed_addr;
}

uint64
sys_munmap(void)
{
  uint64 addr;
  int length;
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0) {
    return -1;
  }
  if (length <= 0) {
    return -1;
  }

  struct proc *p = myproc();
  addr = PGROUNDDOWN(addr); // 起始地址对齐
  length = PGROUNDUP(length); // 长度对齐

  // 1. 查找包含该地址范围的 VMA
  struct vma *vma = 0;
  // int found_index = -1;
  for (int i = 0; i < NVMA; i++) {
    if (p->vmas[i].used &&
        addr >= p->vmas[i].addr &&
        addr + length <= p->vmas[i].addr + p->vmas[i].length) {
      vma = &p->vmas[i];
      // found_index = i;
      break;
    }
  }
  if (vma == 0) {
    return -1; // 没有找到对应的 VMA
  }

  // 2. 如果是 MAP_SHARED 映射，尝试将脏页写回文件
  if ((vma->flags & MAP_SHARED)) {
    // 使用 filewrite 写回从 addr 开始的前 length 字节
    // filewrite 内部会处理页表遍历和拷贝，但我们只应写入已分配且脏的页。
    // 一个更精确的实现会遍历涉及的每个页，检查 PTE_D (Dirty) 位，但这里简化处理，全部写回。
    filewrite(vma->file, addr, length);
  }

  // 3. 解除用户页表映射并释放物理内存
  //    uvmunmap 的第四个参数 (do_free) 为 1 表示要释放物理页
  uvmunmap(p->pagetable, addr, length / PGSIZE, 1);

  // 4. 更新 VMA
  if (addr == vma->addr && length == vma->length) {
    // 情况 A: 完全解除整个映射
    fileclose(vma->file); // 减少文件的引用计数
    vma->used = 0;       // 标记 VMA 为空闲
  } else if (addr == vma->addr) {
    // 情况 B: 从开头解除部分映射
    vma->addr += length;
    vma->length -= length;
    vma->offset += length; // 文件偏移也需要更新！
  } else if (addr + length == vma->addr + vma->length) {
    // 情况 C: 从末尾解除部分映射
    vma->length -= length;
  } else {
    // 情况 D: 从中间解除映射（复杂，本实验可能不要求）
    // 简单处理：返回错误或杀死进程
    return -1;
  }

  // 5. 如果解除的是进程地址空间末尾的映射，更新 p->sz
  //    (这假设映射是从高地址连续分配的，可能不总是成立，但适用于简单实现)
  if (addr + length == p->sz) {
    p->sz = addr;
  }

  return 0;
}