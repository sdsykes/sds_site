pass(s) 
     char *s;
{
  if (i==10) printf("%s passed\n", s);
}

int i = 0;

main() {
  printf("**** loops test ****\n");

  for (; i<10; i++) {
    printf("%d ",i);
  }
  pass("for - no init");
  i = 0;
  for (; ; i++) {
    printf("%d ",i);
    if (i==9) break;
  }
  i++;
  pass("for - no init, no cond");
  i = 0;
  for (; ;) {
    printf("%d ",i);
    if (i++==9) break;
  }
  pass("for - no init, no cond, no inc");
  i = 0;
  while (i < 10) {
    printf("%d ",i);
    i++;
  }
  pass("while");
  i = 0;
  do {
    printf("%d ",i);
    i++;
  } while (i < 10);
  pass("do while");
}
