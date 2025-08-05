#include "kernel/types.h"
#include "kernel/fs.h"
#include "kernel/stat.h"
#include "user/user.h"

/**
 * @brief 递归查找指定目录下名称与给定文件名匹配的文件
 *
 * @param path      要搜索的起始目录路径（必须是目录）
 * @param filename  要查找的目标文件名（仅文件名，不包含路径）
 *
 * 本函数会：
 * 1. 遍历 path 下所有的文件与子目录；
 * 2. 遇到子目录时递归进入；
 * 3. 如果当前文件的名称与 filename 匹配，则打印其完整路径。
 */
void find(char *path, const char *filename)
{
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;

  // 打开目录
  if ((fd = open(path, 0)) < 0) {
    fprintf(2, "find: cannot open %s\n", path);
    return;
  }

  // 获取目录信息
  if (fstat(fd, &st) < 0) {
    fprintf(2, "find: cannot fstat %s\n", path);
    close(fd);
    return;
  }

  // 如果 path 不是目录，则说明使用方式错误
  if (st.type != T_DIR) {
    fprintf(2, "usage: find <DIRECTORY> <filename>\n");
    close(fd);
    return;
  }

  // 检查路径拼接后是否过长
  if (strlen(path) + 1 + DIRSIZ + 1 > sizeof buf) {
    fprintf(2, "find: path too long\n");
    close(fd);
    return;
  }

  // 构造路径前缀（例如 /a -> /a/）
  strcpy(buf, path);
  p = buf + strlen(buf);
  *p++ = '/';

  // 遍历目录项
  while (read(fd, &de, sizeof de) == sizeof de) {
    if (de.inum == 0)
      continue;

    // 构造完整路径名
    memmove(p, de.name, DIRSIZ);
    p[DIRSIZ] = 0;

    // 获取当前路径的 stat 信息
    if (stat(buf, &st) < 0) {
      fprintf(2, "find: cannot stat %s\n", buf);
      continue;
    }

    // 如果是子目录且不是 "." 或 ".."，递归进入
    if (st.type == T_DIR && strcmp(p, ".") != 0 && strcmp(p, "..") != 0) {
      find(buf, filename);
    }
    // 如果是文件名匹配，输出路径
    else if (strcmp(filename, p) == 0) {
      printf("%s\n", buf);
    }
  }

  close(fd);
}

/**
 * @brief 程序入口：处理参数并调用 find()
 *
 * @param argc 参数个数，必须为 3
 * @param argv 参数数组，格式应为：find <directory> <filename>
 *
 * 参数说明：
 * - argv[1]：要查找的目录路径
 * - argv[2]：要查找的文件名
 */
int main(int argc, char *argv[])
{
  if (argc != 3) {
    fprintf(2, "usage: find <directory> <filename>\n");
    exit(1);
  }

  find(argv[1], argv[2]);
  exit(0);
}
