foo(i)
     int i[];
{
  printf("sizeof(i)=%d (1)\n", sizeof(i));
}

main() {
  int i[14];
  printf("**** sizeof test ****\n");
  foo(i);
  printf("sizeof(i)=%d (14)\n", sizeof(i));
}
