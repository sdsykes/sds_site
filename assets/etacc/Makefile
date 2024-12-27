YFLAGS	= -v
CFLAGS	= -O
LFLAGS	=

SRC	= c.y c.lex main.c
INT	= main.c lex.yy.c c.tab.c

all:	parser sseta

sseta:  sseta.c
	cc $(CFLAGS) sseta.c -o sseta

parser:	$(INT)
	cc $(CFLAGS) $(INT) -o parser

lex.yy.c: c.tab.h c.lex
	lex $(LFLAGS) c.lex

c.tab.c: c.y
	bison $(YFLAGS) c.y

clean:
	rm -f parser c.output sseta
