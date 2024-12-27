main(){
  char c[2];
  printf("**** getchar test ****\n");
  printf("Type a single character then return: ");
  c[0] = getchar();
  c[1] = getchar();
  printf("Char was %c, newline was %d\n", c[0], c[1]);
}
