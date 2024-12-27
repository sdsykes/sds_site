#include "libeta.h"

main() {
  char s[10];
  int i=0;
  printf("**** atoi test ****\n");
  printf("Enter number: ");
  while((s[i++]=getchar()) != '\n');
  i = atoi(s);
  printf("Number was %d, string was %s",i,s);
}
