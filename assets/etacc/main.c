#include <stdio.h>
#include <errno.h>
extern char *yylval;
extern int pass;
extern int funccnt;
extern int globalsize;
extern int main_arity;
extern char *funccall(char *name, int arity);
int yyparse();

main(int argc, char *argv[])
{
  int ssize;
  if (argc != 3) {
    fprintf(stderr, "Usage: parser stacksize filename\n");
    exit(1);
  }
  ssize = atoi(argv[1]);
  freopen(argv[2], "r", stdin);
  if (errno) {
    perror("parser");
    exit(2);
  }
  yylval = (char *)malloc(32768);
  /* parse in symbol table */
  pass = 1;
  yyparse();
  /* write prologue */
  printf("require 'eta-rb.rb'\n");
  printf("require 'eta-cc-libs.rb'\n");
  printf("ssize = %d\n", ssize);
  printf("$c = Astack.new(ssize, 0)\n"); /* call stack - function return addresses */
  printf("$l = Astack.new(ssize*3, ssize)\n"); /* local storage stack */
  printf("$e = Astack.new(ssize, 0)\n"); /* expression stack */
  printf("$ea = Astack.new(ssize, 0)\n"); /* expression address stack */
  printf("brk = nil\n"); /* break vector save */
  printf("$cont = []\n"); /* continue stack */
  /* write symbol table */
  write_table();
  printf("$globalsize = %d\n", globalsize);
  /* parse and produce code */
  pass = 2;
  funccnt = 0;
  freopen(argv[2], "r", stdin);
  yyparse();
  /* write epilogue, call main */
  printf("%d.times {$e.push(0);$ea.push(0)}\n",main_arity); /* if main was specified with argc,argv */
  printf("%s", funccall("main",main_arity));
  printf("eexit\n");
  printf("finish\n");

  return(0);
}
