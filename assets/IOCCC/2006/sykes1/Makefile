SHELL= /bin/sh
CFLAGS= -Wall -W -O3 --unroll-loops -ansi
CC= cc
RM= rm

all: sykes1

sykes1: sykes1.c
	${CC} ${CFLAGS} sykes1.c -o sykes1

clean:
	${RM} -f sykes1.o

clobber: clean
	${RM} -f sykes1 cube.gif
