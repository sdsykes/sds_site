/* factors.c -- It prompts the user to enter an integer N. It prints out
 *        if it is a prime or not. If not, it prints out all of its
 *        proper factors.
 */

#include "libeta.h"

int main(void) {
  int n=0, 
    lcv, 
    flag; /* flag initially is 1 and becomes 0 if we determine that n
	     is not a prime */
  char buf[10];

  printf("**** factors test ****\n");
  printf("Enter value of N > ");
  while((buf[n++]=getchar()) != '\n' && n < 10); 
  n = atoi(buf);
  for (lcv=2, flag=1; lcv <= (n / 2); lcv++) {
    if ((n % lcv) == 0) {
      if (flag)
	printf("The non-trivial factors of %d are: \n", n);
      flag = 0;
      printf("\t%d\n", lcv);
    }
  }
  if (flag)
    printf("%d is prime\n", n);
}
