#include "kernel/types.h"
#include "user/user.h"

#define RD 0  // 管道读端
#define WR 1  // 管道写端

/**
 * @brief 读取左边管道的第一个数（应该是素数），打印它
 * @param left 左边传入数据的管道
 * @param prime 存储读到的第一个数
 * @return 成功返回0，失败返回-1
 */
int read_first(int left[2], int *prime) {
  if (read(left[RD], prime, sizeof(int)) == sizeof(int)) {
    printf("prime %d\n", *prime);
    return 0;
  }
  return -1;
}

/**
 * @brief 从左边读取数据，筛选出不能被 prime 整除的数，传到右边
 * @param left 输入管道
 * @param right 输出管道
 * @param prime 当前的素数，用于筛选
 */
void filter_and_pass(int left[2], int right[2], int prime) {
  int num;
  while (read(left[RD], &num, sizeof(int)) == sizeof(int)) {
    if (num % prime != 0) {
      write(right[WR], &num, sizeof(int));
    }
  }
  // 所有数据处理完后，关闭两端
  close(left[RD]);
  close(right[WR]);
}

/**
 * @brief 递归地处理素数筛选
 * @param left 输入管道
 */
void primes(int left[2]) {
  close(left[WR]); // 当前进程只读，不写
  int prime;

  // 读取当前管道的第一个数
  if (read_first(left, &prime) == 0) {
    int right[2];
    pipe(right); // 创建下一个进程用的管道

    // 过滤不能被 prime 整除的数，写入右边管道
    filter_and_pass(left, right, prime);

    // 创建子进程处理下一个筛选
    if (fork() == 0) {
      primes(right); // 子进程继续处理
    } else {
      close(right[RD]); // 父进程不读了
      wait(0);          // 等待子进程结束
    }
  }

  exit(0);
}

int main() {
  int pipe_fd[2];
  pipe(pipe_fd);

  // 写入 2~35 到管道
  for (int i = 2; i <= 35; i++) {
    write(pipe_fd[WR], &i, sizeof(int));
  }

  // 创建子进程开始处理素数筛选
  if (fork() == 0) {
    primes(pipe_fd);
  } else {
    // 父进程关闭读写并等待
    close(pipe_fd[WR]);
    close(pipe_fd[RD]);
    wait(0);
  }

  exit(0);
}
