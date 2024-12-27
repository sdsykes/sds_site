main() {
  int i;
  printf("**** goto test ****\n");
  for (i=0; i<10; i++) {
    if (i==5) goto frog;
    printf("%d ",i);
  }
  printf("not reached");
 frog:
  if (i==5) printf("got here.. ");
  else printf("got here again, passed\n");
  i++;
  if (i<7) goto frog;
}
