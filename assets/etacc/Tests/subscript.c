main() {
  char *s[2];
  printf("**** subscript test ****\n");

  s[1] = "qwerty";
  printf("s[1][3]=%c (r)\n", s[1][3]);
  printf("fixed str sub %c (#)\n", "012345#7"[6]);
}
