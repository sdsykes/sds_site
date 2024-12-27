#include "libeta.h"

main() {
  char *a = "qwerty";
  char b[10];
  printf("**** memset test ****\n");
  strcpy(b,a);
  memset(b+1,'X',3);
  printf("%s (qXXXty), ", b);
  printf("%s (ZZZZZZ)\n", memset(b,'Z',6));
}
