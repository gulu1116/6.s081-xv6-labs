#include "kernel/types.h"
#include "user/user.h"

#define RD 0 //pipe的read端
#define WR 1 //pipe的write端

int main(int argc, char const *argv[]) 
{
    char buf = 'P'; //用于传送的字节

    int fd_c2p[2]; //子进程->父进程
    int fd_p2c[2]; //父进程->子进程
    // 创建两个管道
    if (pipe(fd_p2c) < 0 || pipe(fd_c2p) < 0) {
        fprintf(2, "pipe() error!\n");
        exit(1);
    }

    int pid = fork();

    int exit_status = 0;

    if (pid < 0) {
        fprintf(2, "fork() error!\n");
        close(fd_c2p[RD]);
        close(fd_c2p[WR]);
        close(fd_p2c[RD]);
        close(fd_p2c[WR]);
        exit(1);
    } else if (pid == 0) { //子进程
        close(fd_p2c[WR]);
        close(fd_c2p[RD]);

        if (read(fd_p2c[RD], &buf, sizeof(char)) != sizeof(char)) {
            fprintf(2, "child read() error!\n");
            exit_status = 1; //标记出错
        } else {
            fprintf(1, "%d: received ping\n", getpid());
        }

        close(fd_p2c[RD]);
        close(fd_c2p[WR]);
        exit(exit_status);

    } else { //父进程
        close(fd_p2c[RD]);
        close(fd_c2p[WR]);

        // 发送 ping
        if (write(fd_p2c[WR], &buf, sizeof(char)) != sizeof(char)) {
            fprintf(2, "parent write() error!\n");
            exit_status = 1;
        }

        // 接收 pong
        if (read(fd_c2p[RD], &buf, sizeof(char)) != sizeof(char)) {
            fprintf(1, "parent read() error!\n");
            exit_status = 1;
        } else {
            fprintf(1, "%d: received pong\n", getpid());
        }

        close(fd_p2c[WR]);
        close(fd_c2p[RD]);
        exit(exit_status);
    }

    return 0;
}