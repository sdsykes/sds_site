/* addresses.c -- Playing with addresses of variables and their contents:
 *                what is done by C with variables, addresses, and values.
 */

void moo(int a, int *b);

int main(void) {
  int x;
  int *y;

  printf("**** unary & test ****\n");
  x=888;
  y=&x;
  printf("Address of x = %d, value of x = %d\n", &x, x);
  printf("Address of y = %d, value of y = %d, value of *y = %d\n", &y, y, *y);
  moo(99,y);
  moo(77,y);
}

void moo(int a, int *b){
  printf("Address of a = %d, value of a = %d\n", &a, a);
  printf("Address of b = %d, value of b = %d, value of *b = %d\n", &b, b, *b);
}
