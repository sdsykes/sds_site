#include "libeta.h"

main() {
  char *a = "123456";
  char b[7];
  printf("**** strcpy test ****\n");
  strcpy(b,a);
  strcpy(b+1, a+3);
  printf("%s (1456) strcpy passed\n", b);
}
