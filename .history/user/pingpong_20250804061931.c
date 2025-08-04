#include "kernel/types.h"
#include "user/user.h"

#define RD 0  // 管道读端
#define WR 1  // 管道写端

int main(int argc, char const *argv[]) {
    // 验证参数数量
    if (argc > 1) {
        fprintf(2, "Usage: pingpong (no arguments needed)\n");
        exit(1);
    }

    char buf = 'P';  // 用于在进程间传递的字节

    // 创建两个管道：
    int fd_c2p[2];  // 子进程->父进程的管道
    int fd_p2c[2];  // 父进程->子进程的管道
    
    // 创建管道并检查错误
    if (pipe(fd_c2p) < 0 || pipe(fd_p2c) < 0) {
        fprintf(2, "pipe creation failed\n");
        exit(1);
    }

    int pid = fork();  // 创建子进程
    int exit_status = 0;  // 退出状态码

    if (pid < 0) {
        // fork失败处理
        fprintf(2, "fork() failed!\n");
        // 关闭所有管道端点
        close(fd_c2p[RD]);
        close(fd_c2p[WR]);
        close(fd_p2c[RD]);
        close(fd_p2c[WR]);
        exit(1);
    } else if (pid == 0) {  // 子进程代码块
        // 关闭不需要的管道端点:
        close(fd_p2c[WR]);  // 不需要向父->子管道写入
        close(fd_c2p[RD]);  // 不需要从子->父管道读取

        // 步骤1: 从父进程读取数据
        int nread = read(fd_p2c[RD], &buf, sizeof(char));
        if (nread != sizeof(char)) {
            if (read(fd_p2c[RD], &buf, sizeof(char)) < 0) {
                fprintf(2, "child read() error!\n");
            } else {
                fprintf(2, "child read() incomplete\n");
            }
            exit_status = 1;
        } else {
            // 成功读取后打印消息
            fprintf(1, "%d: received ping\n", getpid());
        }

        // 步骤2: 将数据写回父进程
        if (write(fd_c2p[WR], &buf, sizeof(char)) != sizeof(char)) {
            fprintf(2, "child write() error!\n");
            exit_status = 1;
        }

        // 关闭剩余管道端点
        close(fd_p2c[RD]);
        close(fd_c2p[WR]);

        exit(exit_status);  // 子进程退出
    } else {  // 父进程代码块
        // 关闭不需要的管道端点:
        close(fd_p2c[RD]);  // 不需要从父->子管道读取
        close(fd_c2p[WR]);  // 不需要向子->父管道写入

        // 步骤1: 向子进程发送数据
        if (write(fd_p2c[WR], &buf, sizeof(char)) != sizeof(char)) {
            fprintf(2, "parent write() error!\n");
            exit_status = 1;
        }

        // 步骤2: 等待子进程的回复
        int read_bytes = read(fd_c2p[RD], &buf, sizeof(char));
        if (read_bytes != sizeof(char)) {
            if (read_bytes < 0) {
                fprintf(2, "parent read() error!\n");
            } else {
                fprintf(2, "parent read() incomplete\n");
            }
            exit_status = 1;
        } else {
            // 成功读取后打印消息
            fprintf(1, "%d: received pong\n", getpid());
        }

        // 关闭剩余管道端点
        close(fd_p2c[WR]);
        close(fd_c2p[RD]);

        // 等待子进程结束
        wait(0);
        
        exit(exit_status);  // 父进程退出
    }
}