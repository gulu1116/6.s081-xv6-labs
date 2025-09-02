// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.


#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"

#define NBUCKET 13      // 素数，经验值，可调整
#define HASH(dev, blockno) (((dev) + (blockno)) % NBUCKET)

struct bucket {
  struct buf head;      // 哨兵节点，循环链表
  struct spinlock lock; // 名称需以 "bcache" 开头
};

struct {
  struct buf buf[NBUF];
  struct bucket buckets[NBUCKET];
} bcache;


void
binit(void)
{
  struct buf *b;
  char name[16];

  // 初始化 bucket locks 和头节点（空循环链表）
  for(int i = 0; i < NBUCKET; i++){
    snprintf(name, sizeof(name), "bcache.%d", i); // 名称要以 bcache 开头
    initlock(&bcache.buckets[i].lock, name);
    bcache.buckets[i].head.next = &bcache.buckets[i].head;
    bcache.buckets[i].head.prev = &bcache.buckets[i].head;
  }

  // 初始化 buf 数组并把它们都放入 bucket 0
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    initsleeplock(&b->lock, "buffer");
    // 插入到 bucket 0 的 head 后面
    b->next = bcache.buckets[0].head.next;
    b->prev = &bcache.buckets[0].head;
    bcache.buckets[0].head.next->prev = b;
    bcache.buckets[0].head.next = b;
    b->timestamp = 0;
    b->refcnt = 0;
    b->valid = 0;
    b->dev = 0;
    b->blockno = 0;
  }
}



// struct {
//   struct spinlock lock;
//   struct buf buf[NBUF];

//   // Linked list of all buffers, through prev/next.
//   // Sorted by how recently the buffer was used.
//   // head.next is most recent, head.prev is least.
//   struct buf head;
// } bcache;

// void
// binit(void)
// {
//   struct buf *b;

//   initlock(&bcache.lock, "bcache");

//   // Create linked list of buffers
//   bcache.head.prev = &bcache.head;
//   bcache.head.next = &bcache.head;
//   for(b = bcache.buf; b < bcache.buf+NBUF; b++){
//     b->next = bcache.head.next;
//     b->prev = &bcache.head;
//     initsleeplock(&b->lock, "buffer");
//     bcache.head.next->prev = b;
//     bcache.head.next = b;
//   }
// }

// bget: get a buffer for device dev and blockno.
// If the buffer is cached, return it with refcnt++.
// Otherwise, recycle an unused buffer (LRU) and reinitialize it.
static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;
  int bid = HASH(dev, blockno);
  acquire(&bcache.buckets[bid].lock);

  // 先在当前桶中查找
  for(b = bcache.buckets[bid].head.next; b != &bcache.buckets[bid].head; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      b->refcnt++;
      acquire(&tickslock);
      b->timestamp = ticks;
      release(&tickslock);
      release(&bcache.buckets[bid].lock);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // 没有找到，需要回收一个缓冲区
  struct buf *lru_buf = 0; // 用于记录LRU缓冲区
  int lru_bid = bid;       // LRU缓冲区所在的桶ID

  // 首先在当前桶中寻找LRU缓冲区
  for(b = bcache.buckets[bid].head.next; b != &bcache.buckets[bid].head; b = b->next){
    if(b->refcnt == 0 && (lru_buf == 0 || b->timestamp < lru_buf->timestamp)) {
      lru_buf = b;
      lru_bid = bid;
    }
  }

  // 如果当前桶没有找到，遍历其他桶
  if(lru_buf == 0) {
    for(int i = (bid+1) % NBUCKET; i != bid; i = (i+1) % NBUCKET) {
      acquire(&bcache.buckets[i].lock);
      for(b = bcache.buckets[i].head.next; b != &bcache.buckets[i].head; b = b->next) {
        if(b->refcnt == 0 && (lru_buf == 0 || b->timestamp < lru_buf->timestamp)) {
          lru_buf = b;
          lru_bid = i;
        }
      }
      if(lru_buf) {
        // 找到后，保持该桶的锁，break后继续持有
        break;
      } else {
        release(&bcache.buckets[i].lock);
      }
    }
  }

  if(lru_buf == 0) {
    release(&bcache.buckets[bid].lock);
    panic("bget: no buffers");
  }

  // 如果lru_buf不在当前桶，需要将其移动到当前桶
  if(lru_bid != bid) {
    // 从原桶中移除
    lru_buf->next->prev = lru_buf->prev;
    lru_buf->prev->next = lru_buf->next;
    // 释放原桶的锁
    release(&bcache.buckets[lru_bid].lock);

    // 添加到当前桶
    lru_buf->next = bcache.buckets[bid].head.next;
    lru_buf->prev = &bcache.buckets[bid].head;
    bcache.buckets[bid].head.next->prev = lru_buf;
    bcache.buckets[bid].head.next = lru_buf;
  }

  lru_buf->dev = dev;
  lru_buf->blockno = blockno;
  lru_buf->valid = 0;
  lru_buf->refcnt = 1;
  acquire(&tickslock);
  lru_buf->timestamp = ticks;
  release(&tickslock);
  release(&bcache.buckets[bid].lock);
  acquiresleep(&lru_buf->lock);
  return lru_buf;
}


// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");

  releasesleep(&b->lock);

  int bid = HASH(b->dev, b->blockno);
  acquire(&bcache.buckets[bid].lock);
  if(b->refcnt <= 0)
    panic("brelse: refcnt");
  b->refcnt--;
  if(b->refcnt == 0){
    // 更新时间戳（受 tickslock 保护）
    acquire(&tickslock);
    b->timestamp = ticks;
    release(&tickslock);
  }
  release(&bcache.buckets[bid].lock);
}


void
bpin(struct buf *b)
{
  int bid = HASH(b->dev, b->blockno);
  acquire(&bcache.buckets[bid].lock);
  b->refcnt++;
  release(&bcache.buckets[bid].lock);
}

void
bunpin(struct buf *b)
{
  int bid = HASH(b->dev, b->blockno);
  acquire(&bcache.buckets[bid].lock);
  if(b->refcnt <= 0)
    panic("bunpin");
  b->refcnt--;
  release(&bcache.buckets[bid].lock);
}


