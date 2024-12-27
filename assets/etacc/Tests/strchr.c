#include "libeta.h"

main() {
  char *a = "qwerty";
  printf("**** strchr test ****\n");
  printf("%c (y), %d (4), %d (0)\n", *strchr(a, 'y'), strchr(a, 't') - a, strchr(a, 'z'));
}
