main() {
  int i,j;
  char *p = "L    o    o    p    .";
  char *z = p;
  printf("**** loop nesting test ****\n");
  for(i=0;i<10;i++) {
    if (!(i%2)) continue;
    printf("%c ",*(z++));
    for(j=0;j<10;j++) {
      if (!(j%2)) continue;
      if (j>7) break;
      z+=1;
    }
  }
  printf("Loop nesting passed\n");
}
