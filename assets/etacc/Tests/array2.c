foo() {
  char y[3][3][4];
  int i,j;
  printf("sizeof(y)=%d\n", sizeof(y));
  for (i=0;i<3;i++) {
    for (j=0;j<3;j++) {
      y[i][j][0] = '0' + i*3 + j;
      y[i][j][1] = 'A' + i*3 + j;
      y[i][j][2] = 'a' + i*3 + j;
      y[i][j][3] = '\0';
    }
  }
  for (i=0;i<3;i++) {
    for (j=0;j<3;j++) {
      printf("%s ",y[i][j]);
    }
    printf("\n");
  }
}

main() {

  char *x[2][2];
  int i;

  printf("**** multi-dimension arrays test ****\n");
  printf("sizeof(x)=%d\n", sizeof(x));
  x[0][0] = "Up   Left";
  x[0][1] = "Up   Right";
  x[1][0] = "Down Left";
  x[1][1] = "Down Right";

  for (i=0; i<2; i++) {
    printf("%s - %s\n",x[i][0],x[i][1]);
  }
  foo();
}

 
