#include "kernel/types.h"
#include "user/user.h"

#define RD 0 // pipe读端
#define WR 1 // pipe写端

int
main(int argc, char const *argv[]) {
    char buf = 'P'; // 用于传送的字节

    int fd_p2c[2]; // 父 -> 子
    int fd_c2p[2]; // 子 -> 父

    // 创建两个管道
    if (pipe(fd_p2c) < 0 || pipe(fd_c2p) < 0) {
        fprintf(2, "pipe() error!\n");
        exit(1);
    }

    int pid = fork();
    if (pid < 0) {
        fprintf(2, "fork() error!\n");
        close(fd_p2c[RD]); close(fd_p2c[WR]);
        close(fd_c2p[RD]); close(fd_c2p[WR]);
        exit(1);
    }

    if (pid == 0) {
        // -------- 子进程 --------
        // 关闭不使用的端
        close(fd_p2c[WR]);
        close(fd_c2p[RD]);

        // 接收 ping
        if (read(fd_p2c[RD], &buf, sizeof(char)) != sizeof(char)) {
            fprintf(2, "child read() error!\n");
            close(fd_p2c[RD]);
            close(fd_c2p[WR]);
            exit(1);
        }

        // 打印接收到的信息
        fprintf(1, "%d: received ping\n", getpid());

        // 回复 pong
        if (write(fd_c2p[WR], &buf, sizeof(char)) != sizeof(char)) {
            fprintf(2, "child write() error!\n");
            close(fd_p2c[RD]);
            close(fd_c2p[WR]);
            exit(1);
        }

        // 清理资源并退出
        close(fd_p2c[RD]);
        close(fd_c2p[WR]);
        exit(0);
    } else {
        // -------- 父进程 --------
        // 关闭不使用的端
        close(fd_p2c[RD]);
        close(fd_c2p[WR]);

        // 发送 ping
        if (write(fd_p2c[WR], &buf, sizeof(char)) != sizeof(char)) {
            fprintf(2, "parent write() error!\n");
            close(fd_p2c[WR]);
            close(fd_c2p[RD]);
            wait(0);
            exit(1);
        }

        // 接收 pong
        if (read(fd_c2p[RD], &buf, sizeof(char)) != sizeof(char)) {
            fprintf(2, "parent read() error!\n");
            close(fd_p2c[WR]);
            close(fd_c2p[RD]);
            wait(0);
            exit(1);
        }

        // 打印接收到的信息
        fprintf(1, "%d: received pong\n", getpid());

        // 清理资源
        close(fd_p2c[WR]);
        close(fd_c2p[RD]);

        // 等待子进程结束
        wait(0);
        exit(0);
    }
}
