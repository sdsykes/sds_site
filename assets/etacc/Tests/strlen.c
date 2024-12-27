#include "libeta.h"

main() {
  char *a = "123456";
  char b[7];
  printf("**** strlen test ****\n");
  strcpy(b,a);
  printf("%d",strlen(b));
  strcpy(b+1, a+3);
  printf("%d (64) strlen passed\n", strlen(b));
}
