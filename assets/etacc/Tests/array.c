#include "libeta.h"
#define SIZE 8

void cpIntArray(int *a, int *b, int n)
     /*It copies n integers starting at b into a*/
{
  for(;n>0;n--)
    *a++=*b++;
}


void printIntArray(int a[], int n)
     /* n is the number of elements in the array a.
      * These values are printed out, five per line. */
{
  int i;

  for (i=0; i<n; ){
    printf("\t%d ", a[i++]);
    if (i%5==0)
      printf("\n");
  }
  printf("\n");
}

int getIntArray(int a[], int nmax)
     /* sets array up with nmax integers starting at start */
{
  int n = 0;
  int temp,i;
  char s[10];
  i = 0;
  printf("Enter start integer: ");
  while((s[i++]=getchar()) != '\n' && i<10);
  temp = atoi(s);
  do {
    if (n==nmax)
      break;
    else {
      a[n++] = temp++;
    }
  } while (1);
  return n;
}

int main(){
  int x[SIZE], nx;
  int y[SIZE], ny;

  printf("**** arrays test ****\n");
  printf("Make the x array:\n");
  nx = getIntArray(x,SIZE);
  printf("The x array is:\n");
  printIntArray(x,nx);

  printf("Make the y array:\n");
  ny = getIntArray(y,SIZE);
  printf("The y array is:\n");
  printIntArray(y,ny);

  cpIntArray(x+2,y+3,4);
  printf("Printing x after having copied 4 elements\nfrom y starting at y[3] into x starting at x[2]\n");
  printIntArray(x,nx);
}
