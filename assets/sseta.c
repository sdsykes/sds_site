// ETA optimising interpreter
// This should run at least 5 times faster than a conventional interpreter
// And with some code you could be looking at huge improvements (>100x)
//
// Usage: sseta programname
//
// A programname.compiled file will be generated - you don't need this, but
// it is interesting to see the reduced version of the ETA code
//
// Version 1.0 S.D.Sykes 4/2/2002 - yes I know it's not clean or pretty!
// Version 1.1 S.D.Sykes 6/2/2002 - many further optimisations, and the 
// ability to run programs with numbers that cross line boundaries

#include <stdio.h>
#include <string.h>

#include <stdlib.h>
#include <ctype.h>

// you might need these if your system doesn't support index/rindex
#define index strchr
#define rindex strrchr

#define MAXLINELEN 12000 /*1024*/
#define MAXLINES 1      /* times 64k */
#define MAXCHARS 8     /* times 64k */
#define STACKSIZE 4096

char program[65536 * MAXCHARS];
int  preints[65536 * MAXCHARS];
char *linestarts[65536 * MAXLINES];
char *program_end;
int numlookup[] = {2,0,0,0,0,0,0,0,4,0,0,0,0,5,3,0,0,0,6,1};

void loadprogram(char *f) {
  char line[MAXLINELEN];
  char *bufptr = program;
  int linesread = 1;
  FILE *fd, *fc;
  char fcn[512]; // dangerous
  int c;
  int in_num = 0;
  int numacc;
  int zerocount = 0, abcount=0, zhcount=0, khnegcount=0, khposcount=0, kscount=0, usscount=0;
  int zkscount = 0, doublezerocount = 0, akstcount = 0, ksatcount = 0, zscount = 0, zasscount=0;
  int ktcount = 0;
  int cl_below, cl_next_flag = 0;      // cl_below is where in this line to avoid optimisation to
                                       // cl_next_flag indicates there is a crossline carrying over

  if (!(fd = fopen(f,"r"))) {
    fprintf(stderr, "ETA file not found\n");
    exit(1);
  }
  strncpy(fcn,f,500);
  strcat(fcn,".compiled");
  if (!(fc = fopen(fcn,"w"))) {
    fprintf(stderr, "ETA can't open compilation file for writing\n");
    exit(1);
  }
  fprintf(stderr, "ETA reading source\n");
  while (fgets(line, MAXLINELEN, fd)) {
    for (c=0; c<strlen(line); c++) {
      if (!index("etaoinsh\n",line[c])) {
        line[c] = tolower(line[c]);
        if (!index("etaoinsh\n",line[c])) {
          int j;
          for (j=c--; j<strlen(line); j++) line[j] = line[j+1]; // zap non eta char 
        }
      }
    }

    cl_below = 0;
    if (cl_next_flag) {
      if (index(line,'e')) {
        cl_below = (index(line,'e') - line) + 1;
        cl_next_flag = 0;
      } else {
        cl_below = strlen(line);  // num not terminated - carry over to another line...
      }
    }
    if (index(line,'n') && index(line,'e') && rindex(line,'n') > rindex(line,'e')) {
      cl_next_flag = 1;
    }

// Try parsing this with your eyes...
#define CLF (cl_next_flag?(index(line,'n')?index((index(line,'e')?rindex(line,'e'):line),'n')-line:0):strlen(line))

    for (c=cl_below; c < CLF ; c++) {  // optimisation pass 1: numbers
      int j;
      if (in_num && line[c] == 'e') {
        int k_ptr;
        in_num = 0;
        for (j=c--; j<strlen(line); j++) line[j] = line[j+1]; // zap e
        k_ptr = (bufptr + c) - program;
        preints[k_ptr] = numacc;
        if (c && line[c-1] == 'Z' && line[c+1] == 's') {  // got ZKs
          for (j=c+1; j<strlen(line); j++) line[j] = line[j+1];  // zap s
          for (j= --c; j<strlen(line); j++) line[j] = line[j+1]; // zap Z
          k_ptr = (bufptr + c) - program;
          preints[k_ptr] = -numacc;
          zkscount++;
        }
      } else if (!in_num && line[c] == 'n') {
        in_num = 1;
        line[c] = 'K';
        numacc = 0;
        if (line[c+1] == 'e') {
          line[c] = 'Z';  // special case zero
          zerocount++;
          in_num = 0;
          for (j=c+1; j<strlen(line); j++) line[j] = line[j+1];    // zap e
          if (line[c+1] == 's') {                  // Zs, does nothing, delete
            for (j=c+1; j<strlen(line); j++) line[j] = line[j+1];    // zap s
            for (j=c--; j<strlen(line); j++) line[j] = line[j+1];    // zap Z
            zscount++;
          } else if (c && line[c-1] == 'Z') {      // double zero
            for (j=c--; j<strlen(line); j++) line[j] = line[j+1];  // zap 2nd Z
            line[c] = 'Q';
            doublezerocount++;
          }
        }
      } else if (in_num) {
        numacc = numacc * 7 + numlookup[line[c]-'a'];
        for (j=c--; j<strlen(line); j++) line[j] = line[j+1];
      }
    }
    
    for (c=cl_below; c<CLF; c++) {  // optimisation pass 2: branches & other sequences
      int j;
      int k_ptr;
      if (line[c]=='a' && line[c+1]=='K' && line[c+2]=='s' && line[c+3]=='t') {
        line[c]='B';
        k_ptr = (bufptr + c) - program;
        preints[k_ptr] = preints[k_ptr + 1];
        for (j=c+1; j<strlen(line)-2; j++) {
          line[j] = line[j+3];  // zap Kst
          preints[(bufptr + j) - program] = preints[(bufptr + j + 3) - program]; // move preints
        }
        akstcount++;
      }
      if (line[c]=='K' && line[c+1]=='s' && line[c+2]=='a' && line[c+3]=='t') {
        for (j=c+1; j<strlen(line)-2; j++) {
          line[j] = line[j+3];  // zap sat
          preints[(bufptr + j) - program] = preints[(bufptr + j + 3) - program];
        }
        line[c]='C';
        ksatcount++;
      }
      if (line[c]=='Z' && line[c+1]=='a' && line[c+2]=='s' && line[c+3]=='s') {
        for (j=c+1; j<strlen(line)-2; j++) {
          line[j] = line[j+3];  // zap ass
          preints[(bufptr + j) - program] = preints[(bufptr + j + 3) - program];
        }
        line[c]='D';
        zasscount++;
      }
      if (line[c]=='Z' && line[c+1]=='h') { // dup top stack item
        for (j=c+1; j<strlen(line); j++) {
          line[j] = line[j+1];  // zap h
          preints[(bufptr + j) - program] = preints[(bufptr + j + 1) - program];
        }
        line[c]='U';
        zhcount++;
      }
      if (line[c]=='K' && line[c+1]=='t') {
        for (j=c+1; j<strlen(line); j++) {
          line[j] = line[j+1];  // zap t
          preints[(bufptr + j) - program] = preints[(bufptr + j + 1) - program];
        }
        line[c]='L';
        ktcount++;
      }
      if (line[c]=='U' && line[c+1]=='s' && line[c+2]=='s') {
        for (j=c+1; j<strlen(line)-1; j++) {
          line[j] = line[j+2];  // zap ss
          preints[(bufptr + j) - program] = preints[(bufptr + j + 2) - program];
        }
        line[c]='W';
        usscount++;
      }
      if (line[c]=='K' && line[c+1]=='h') { // constant halibut
        for (j=c+1; j<strlen(line); j++) {
          line[j] = line[j+1];  // zap h
          preints[(bufptr + j) - program] = preints[(bufptr + j + 1) - program];
        }
        if (preints[(bufptr + c) - program] <= 0) { // zeros should have been caught above in fact
          line[c]='F';
          khnegcount++;
        } else {
          line[c]='G';
          if (preints[(bufptr + c) - program]==1) line[c]='1';
          if (preints[(bufptr + c) - program]==2) line[c]='2';
          if (preints[(bufptr + c) - program]==3) line[c]='3';
          khposcount++;
        }
      }
      if (line[c]=='K' && line[c+1]=='s') { // constant subtraction
        for (j=c+1; j<strlen(line); j++) {
          line[j] = line[j+1];  // zap s
          preints[(bufptr + j) - program] = preints[(bufptr + j + 1) - program];
        }
        line[c]='M';
        kscount++;
      }
    }

    for (c=cl_below; c<CLF; c++) {  // optimisation pass 3: complex branches
      int j;
      if (line[c]=='a' && line[c+1]=='B') {
        for (j=c; j<strlen(line); j++) {
          line[j] = line[j+1];  // zap a
          preints[(bufptr + j) - program] = preints[(bufptr + j + 1) - program];
        }
        line[c]='E';
        abcount++;
      }
    } 

    strcpy(bufptr, line);
    fprintf(fc,"%s",line);
    linestarts[linesread++] = bufptr;
    bufptr += strlen(line);
  }
  program_end = bufptr;
  fprintf(stderr, "ETA lines:%d, compiled bytes:%d\nOptimisations: Z:%d, ZKs:%d, ZZ:%d, aKst(B):%d\nKsat(C):%d, Zs:%d, Zass(D):%d, aB(E):%d, Zh(U):%d\nKhNeg(F):%d, KhPos(G):%d, Ks(M):%d, Uss(W):%d, Kt(L):%d\n", 
          linesread, program_end-program, zerocount, zkscount, doublezerocount,
          akstcount, ksatcount, zscount, zasscount, abcount, zhcount, khnegcount,
          khposcount, kscount, usscount, ktcount);
  fclose(fd); fclose(fc);
}

typedef struct st_s {
  int v;
  struct st_s *prev;
  struct st_s *next;
} STACK_TYPE, *STACK_PTR;

STACK_TYPE stack[STACKSIZE];
STACK_PTR stackptr;
STACK_PTR end_node;
STACK_PTR start_node;
int memoryh;
STACK_PTR memoryp;

int stack2[STACKSIZE];
int stack2ptr=0;

int lineno = 1;

void initstack() {
  int c;

  start_node = stackptr = stack;
  start_node->prev = 0;

  for (c=0; c<STACKSIZE; c++) {
    if (c<STACKSIZE-1) stack[c].next = &stack[c+1];
    if (c>0) stack[c].prev = &stack[c-1];
  }
  end_node = &stack[STACKSIZE-1];
  end_node->next = 0;

}

int pop() {
  if (stackptr == start_node) {
    fprintf(stderr,"ETA stack underflow, line %d\n", lineno);
    exit(1);
  }
  stackptr = stackptr->prev;
  if (memoryp) memoryp=memoryp->prev;

  return stackptr->v;
}

void push(int n) {
  if (stackptr == end_node) {
    fprintf(stderr,"ETA stack overflow, line %d\n", lineno);
    exit(1);
  }
  stackptr->v = n;
  stackptr = stackptr->next;
  if (memoryp) memoryp=memoryp->next;
}

void halibut(int h) {
  STACK_PTR p;
  int c,ah;

  p = stackptr->prev;
  if (!p) {
    fprintf(stderr, "ETA halibut below bottom of zero length stack\n");
    exit(1);
  }
  ah = c = abs(h);
  if (ah < 10 || memoryh != c || !memoryp) {
    for(;c>0; c--) {
      p = p->prev;
      if (!p) {
        fprintf(stderr, "ETA halibut below bottom of stack h:%d, lineno %d\n", h, lineno);
        exit(1);
        p = start_node;
        break;
      }
    }
  } else p = memoryp;
  if (ah >= 10) {
    memoryp = p;
    memoryh = ah;
  }
  if (h<=0) push(p->v);
  else {
    if (ah >= 10) memoryp = p->next;
    if (p==start_node) start_node = p->next;
    else (p->prev)->next = p->next;
    (p->next)->prev = p->prev;

    p->prev = stackptr->prev;
    (stackptr->prev)->next = p;
    p->next = stackptr;
    stackptr->prev = p;
  }
}

void runprogram() {
 char *ip = program;

 fprintf(stderr, "ETA initilising stack\n");

 initstack();

 fprintf(stderr, "ETA running eta code\n");

 while (1) {
  switch(*ip) {
    case 'e': { // divide
      int x = pop();
      int y = pop();
      push (y/x);
      push (y%x);
      break;
    }
    case 't': { // transfer
      int a = pop();
      int c = pop();
      if (c != 0) {
        if (a < 0) {
          fprintf(stderr, "ETA transfer to negative line number, line %d\n", lineno);
          exit(1);
        }
        ip = linestarts[a] - 1; // will be incremented later
        lineno = a;
        if (!lineno) {printf ("\n");exit(0);}   // transfer to zero means exit
      }
      break;
    }
    case 'a': { // address
      push(lineno+1);
      break;
    }
    case 's': { // subtract
      int x = pop();
      int y = pop();
      push (y-x);
      break;
    }
    case 'o': { // output
      putchar(pop());
      fflush(stdout);
      break;
    }
    case 'i': { // input
      int i = getchar();
      if (i == EOF) i = -1;
      push(i);
      break;
    }
    case 'h': { // halibut
      halibut(pop());
      break;
    }
    case 'K': { // pre-compiled number
      push(preints[ip - program]);
      break;
    }
    case 'Z': { // zero shortcut
      push(0);
      break;
    }
    case 'Q': { // double zero shortcut
      push(0);
      push(0);
      break;
    }
    case 'B': { // aKst destination computed branch
      int a = lineno + 1 - preints[ip - program];
      int c = pop();
      if (c != 0) {
        if (a < 0) {
          fprintf(stderr, "ETA transfer to negative line number, line %d\n", lineno);
          exit(1);
        }
        ip = linestarts[a] - 1; // will be incremented later
        lineno = a;
        if (!lineno) {printf ("\n");exit(0);}   // transfer to zero means exit
      }
      break;
    }
    case 'E': { // aaKst destination computed must branch (aB)
      int a = lineno + 1 - preints[ip - program];
      if (a < 0) {
        fprintf(stderr, "ETA transfer to negative line number, line %d\n", lineno);
        exit(1);
      }
      ip = linestarts[a] - 1; // will be incremented later
      lineno = a;
      if (!lineno) {printf ("\n");exit(0);}   // transfer to zero means exit
      break;
    }
    case 'C': { // Ksat condition computed branch
      int a = lineno + 1;
      int c = pop() - preints[ip - program];
      if (c != 0) {
        ip = linestarts[a] - 1; // will be incremented later
        lineno = a;
      }
      break;
    }
    case 'L': { // fixed dest branch
      int a = preints[ip - program];
      int c = pop();
      if (c != 0) {
        ip = linestarts[a] - 1; // will be incremented later
        lineno = a;
      }
      break;
    }
    case 'D': { // Zass shortcut
      push (pop() + lineno + 1);
      break;
    }
    case 'U': { // Zh shortcut
      push((stackptr->prev)->v);
      break;
    }
    case 'W': { // Uss shortcut
      pop();
      break;
    }
    case 'M': { // Ks shortcut
      (stackptr->prev)->v -= preints[ip - program];
      break;
    }
    case 'F': { // KhNeg shortcut
      halibut(preints[ip - program]);
      break;
    }
    case '1': { // swap top two elems
      STACK_PTR pp,p = stackptr->prev;
      if (p && (pp=p->prev)) {
        int temp = p->v;
        p->v = pp->v;
        pp->v = temp;
      } else {
        fprintf(stderr, "ETA halibut below bottom of stack h:1, lineno %d\n", lineno);
        exit(1);
      }
      break;
    }
    case '2': { // halibut top three elems
      STACK_PTR ppp,pp,p = stackptr->prev;
      if (p && (pp=p->prev) && (ppp=pp->prev)) {
        int temp = ppp->v;
        ppp->v = pp->v;
        pp->v = p->v;
        p->v = temp;
      } else {
        fprintf(stderr, "ETA halibut below bottom of stack h:2, lineno %d\n", lineno);
        exit(1);
      }
      break;
    }
    case '3': { // not worth special casing
      halibut(3);
      break;
    }
    case 'G': { // KhPos shortcut
      int x = preints[ip - program];
      if (x == memoryh && memoryp) { // hit
        STACK_PTR p = memoryp;
        memoryp = p->next;
        if (p==start_node) start_node = p->next;
        else (p->prev)->next = p->next;
        (p->next)->prev = p->prev;
        p->prev = stackptr->prev;
        (stackptr->prev)->next = p;
        p->next = stackptr;
        stackptr->prev = p;
      } else halibut(x);
      break;
    }
    case '\n': {
      lineno++;
      break;
    }
    case 'n': {
      int numacc=0;
      while (1) {
        ip += 1;
        if (ip >= program_end) {
          fprintf(stderr, "\nETA fell off end of program\n");
          exit(1);  // fell off end
        }
        if (*ip == 'e') {
          push(numacc);
          break;
        } else if (*ip == '\n') {
          lineno++;
        } else {
          numacc = numacc * 7 + numlookup[*ip - 'a'];
        }
      }
      break;
    }
   } // switch
   ip += 1;
   if (ip >= program_end) {
     fprintf(stderr, "\nETA fell off end of program\n");
     exit(1);  // fell off end
   }
  }  // while
}

int main (int argc, char *argv[]) {
  loadprogram(argv[1]);
  runprogram();
}
