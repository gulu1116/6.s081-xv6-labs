#include "kernel/types.h"
#include "kernel/fs.h"
#include "kernel/stat.h"
#include "user/user.h"

// 递归查找函数
void find(char *path, const char *filename)
{
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;

  // 打开目录（或文件）
  if ((fd = open(path, 0)) < 0) {
    fprintf(2, "find: cannot open %s\n", path);
    return;
  }

  // 获取文件状态信息（包括类型、大小、inode等）
  if (fstat(fd, &st) < 0) {
    fprintf(2, "find: cannot fstat %s\n", path);
    close(fd);
    return;
  }

  // 如果打开的不是目录，报错退出（find 只对目录有效）
  if (st.type != T_DIR) {
    fprintf(2, "usage: find <DIRECTORY> <filename>\n");
    return;
  }

  // 防止路径过长导致缓冲区溢出
  if (strlen(path) + 1 + DIRSIZ + 1 > sizeof buf) {
    fprintf(2, "find: path too long\n");
    return;
  }

  // 构建子路径前缀：例如 path = /a，buf = "/a/"
  strcpy(buf, path);
  p = buf + strlen(buf);
  *p++ = '/';  // 在 path 后添加 '/'

  // 遍历目录项（每次读取一个 dirent 结构）
  while (read(fd, &de, sizeof de) == sizeof de) {
    if (de.inum == 0) // 无效目录项，跳过
      continue;

    // 将文件名复制到 buf 的末尾，构造完整路径
    memmove(p, de.name, DIRSIZ);
    p[DIRSIZ] = 0;  // 字符串结束符，保证 buf 是合法字符串

    // 获取这个目录项的 stat 信息
    if (stat(buf, &st) < 0) {
      fprintf(2, "find: cannot stat %s\n", buf);
      continue;
    }

    // 如果是目录，且不是 "." 或 ".."，则递归查找子目录
    if (st.type == T_DIR && strcmp(p, ".") != 0 && strcmp(p, "..") != 0) {
      find(buf, filename);  // 递归调用
    }
    // 如果当前文件名和目标 filename 相同，打印路径
    else if (strcmp(filename, p) == 0)
      printf("%s\n", buf);
  }

  close(fd);  // 关闭当前目录文件描述符
}

int main(int argc, char *argv[])
{
  // 参数校验：必须是 find <目录> <文件名>
  if (argc != 3) {
    fprintf(2, "usage: find <directory> <filename>\n");
    exit(1);
  }

  // 调用查找函数
  find(argv[1], argv[2]);
  exit(0);
}