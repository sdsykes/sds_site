#include "libeta.h"

main() {
  char *a = "123456";
  char b[7];
  printf("**** strcmp test ****\n");
  strcpy(b,a);
  printf("%d",strcmp(a,b));
  printf(" %d",strcmp(a,"123457"));
  printf(" %d",strcmp(a,"12"));
  printf(" (0 - +) strcmp passed\n");
}
