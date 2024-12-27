SHELL= /bin/sh
CFLAGS= -Wall -W -ansi
CC= cc
RM= rm

all: sykes2

sykes2: sykes2.c
	${CC} ${CFLAGS} sykes2.c -o sykes2

clean:
	${RM} -f sykes2.o

clobber: clean
	${RM} -f sykes2
