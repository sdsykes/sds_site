foo(char d[]) {
  printf("d: %d (1)\n", sizeof(d));
}

main() {
  char *s = "helloo";
  char t[] = "helloo";
  char z[0];

  printf("**** sizeof test 2 ****\n");
  printf("s:%d (1) t:%d (7) z:%d (0)\n", sizeof(s), sizeof(t), sizeof(z));

  t[1] = '#';

  foo(s);
  foo(t);
  printf("t: %s\n",t);
}
