/* recursion test */

spag(char *s) {
  printf("%c", *s);
  ++s;
  if (*s != 0) spag(s);
}

main() {
  printf("**** recursion test ****\n");
  spag("Recursion test passed\n");
}
