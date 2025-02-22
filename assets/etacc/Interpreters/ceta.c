/*
 * $Id: eta.c,v 1.1.1.1 2002/09/13 14:06:17 mike Exp $
 *
 * Interpret ETA code.
 * 
 * Started and finished on: 7th September 1999
 * Harvey Thompson (harveyt@sco.com)
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <unistd.h>
#include <errno.h>
#include <limits.h>

/*
 * An eta_t should also be a signed 32 bit integer.  We assign the minimum
 * and maximum values to get us this portably (assuming that the system
 * supports at least 32 bit integers).  According to ANSI C this should
 * work.
 */
typedef enum eta {
	E, T, A, O, I, N, S, H,	/* instructions */
	NL,			/* psuedo instruction for '\n' */
	CR,			/* psuedo instruction for '\r' */
	IGN,			/* psuedo instruction for anything else */
	ETA_MIN = -2147483647,	/* minium value */
	ETA_MAX = 2147483647
} eta_t;

/*
 * Return the character name of eta_t instructions.
 */
#define eta_name(i) ("HTAOINS\n."[(i)])

/*
 * Bytes are 8 bit unsigned values.  Eta instructions are packed into bytes.
 * They could actually be packed further, but never mind.
 */
typedef unsigned char	byte_t;


/*
 * Current file and line number executing.
 */
const char *	File;
eta_t		Line;

/*
 * Non-zero if verbose.
 */
int		Verbose = 0;

/*
 * Output an error.
 */
void
error(const char *fmt, ...)
{
	va_list	ap;

	va_start(ap, fmt);
	fprintf(stderr, "%s:%d: ", File, Line);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
	if (errno)
		fprintf(stderr, ": %s (errno %d)\n", strerror(errno), errno);
	else
		fputc('\n', stderr);
	exit(1);
}

/*
 * A buffer is a dynamically growable byte array.
 */
typedef struct buf {
	byte_t		*buf;
	size_t		len;
	size_t		maxlen;
} buf_t;

buf_t *
buf_alloc()
{
	buf_t	*bp;

	if ((bp = malloc(sizeof(buf_t))) == NULL
	    || (bp->buf = malloc(1)) == NULL)
		error("cannot malloc buffer");
	bp->len = 0;
	bp->maxlen = 1;
	return bp;
}

void
buf_free(buf_t *	bp)
{
	free(bp->buf);
	free(bp);
}

/*
 * Add `data' of length `len' into end of `bp'.
 */
void
buf_push(buf_t *	bp,
	 const byte_t *	data,
	 size_t		len)
{
	if ((bp->len + len) >= bp->maxlen) {
		bp->maxlen = bp->len + 2 * len;
		if ((bp->buf = realloc(bp->buf, bp->maxlen)) == NULL)
			error("cannot realloc buffer");
	}
	memcpy(bp->buf + bp->len, data, len);
	bp->len += len;
}

/*
 * Remove `len' bytes from end of `bp'.  Returns non-zero if we can do this.
 */
int
buf_pop(buf_t *		bp,
	size_t		len)
{
	if (bp->len < len)
		return 0;
	bp->len -= len;
	return 1;
}

/*
 * How to convert a byte into an eta_t instruction packed in a byte_t.
 */
byte_t	Conv[CHAR_MAX];

void
init_conv()
{
	int	c;
	char *	sp;

	for (c = 0; c <= CHAR_MAX; c++)
		Conv[c] = IGN;
	Conv['E'] = E; Conv['e'] = E;
	Conv['T'] = T; Conv['t'] = T;
	Conv['A'] = A; Conv['a'] = A;
	Conv['O'] = O; Conv['o'] = O;
	Conv['I'] = I; Conv['i'] = I;
	Conv['N'] = N; Conv['n'] = N;
	Conv['S'] = S; Conv['s'] = S;
	Conv['H'] = H; Conv['h'] = H;
	Conv['\n'] = NL; Conv['\r'] = CR;
}

/*
 * A line of instructions are made up of bytes, each containing up to two
 * instructions.
 * 
 * Returns NULL if at end of file.
 */
buf_t *
read_line(FILE *	fp)
{
	buf_t	*bp;
	byte_t	ins;
	int	c;

	if (fp == stdin) {
		fprintf(stderr, "ETA> ");
		fflush(stderr);
	}

	bp = buf_alloc();
	while ((c = fgetc(fp)) != EOF) {
		if ((ins = Conv[c]) == IGN)
			continue;
		if (ins == NL || ins == CR) {
			c = fgetc(fp);
			if (Conv[c] != (ins == NL ? CR : NL))
				ungetc(c, fp);
			break;
		}
		buf_push(bp, &ins, sizeof(ins));
	}
	if (c == EOF && bp->len == 0) {
		buf_free(bp);
		return NULL;
	}
	return bp;
}

/*
 * The current stack.
 */
buf_t	*Stack;

/*
 * The currently accumulating number.
 */
eta_t	Number;

/*
 * Non-zero if accumulating number.
 */
int	In_number;

/*
 * Output stack.
 */
void
show_stack()
{
	size_t	n;

	if (Verbose <= 1)
		return;
		
	fputs("\tSTACK: ", stderr);
	for (n = 0; n < Stack->len; n += sizeof(eta_t))
		fprintf(stderr, "%d ", *((eta_t *)(Stack->buf + n)));
	fputc('\n', stderr);
}

/*
 * Verbose output.
 */
void
verb(const char *fmt, ...)
{
	va_list	ap;

	va_start(ap, fmt);
	if (Verbose)
		vfprintf(stderr, fmt, ap);
	va_end(ap);
}

eta_t
pop()
{
	if (!buf_pop(Stack, sizeof(eta_t)))
		error("stack underflow");
	return *((eta_t *)(Stack->buf + Stack->len));
}

void
push(eta_t	n)
{
	buf_push(Stack, (const byte_t *)&n, sizeof(n));
}

void
roll(eta_t	n)
{
	int	dup = 0;
	eta_t	top, *np, *tp;

	if (n <= 0) {
		dup = 1;
		n = -n;
	}

	/*
	 * roll stack n places
	 */
	top = (eta_t)(Stack->len / sizeof(eta_t));
	if (n < 0 || n >= top)
		error("H %s%d, no such element, have %d",
		      (dup ? "-" : ""), n, top);

	n = (top - 1) - n;
	np = ((eta_t *)Stack->buf) + n;
	tp = ((eta_t *)Stack->buf) + top;
	if (dup) {
		/*
		 * dup nth entry to top of stack
		 */
		push(*np);
		return;
	}

	/*
	 * roll nth entry to top of stack
	 */
	top = top - n - 1;
	n = *np;
	memmove(np, np + 1, (top * sizeof(eta_t)));
	tp[-1] = n;
}

eta_t
run_line(buf_t	*line)
{
	size_t	n;
	byte_t	*bp;
	eta_t	ins, a, b, r;
	int	valid;

	verb("Executing line %d\n", Line);
	show_stack();

	for (bp = line->buf, n = line->len; n; n--, bp++) {
		ins = *bp;
		if (In_number) {
			switch (ins) {
			case E:
				In_number = 0;
				if (Number < 0)
					error("N overflow, %d", Number);
				push(Number);
				verb("\t[E]\n", Number);
				show_stack();
				continue;

			case H:
				ins = E;
				break;
			}
			Number *= 7;
			Number += ins;
			if (Verbose > 2)
				verb("\t[%c -> num=%d]\n", eta_name(ins),
				     Number);
			continue;
		}

		switch(ins) {
		default:
			b = pop();
			switch (ins) {
			case E: /* dividE */
				a = pop();
				push(a / b);
				r = a % b;
				verb("\tE nom=%d div=%d\n", a, b);
				break;
			
			case T: /* Transfer */
				a = pop();
				verb("\tT addr=%d cond=%d\n", b, a);
				show_stack();
				if (a)
					return b;
				continue;

			case O: /* Output */
				if (!isascii(b))
					error("non-ascii O value %d\n", b);
				putchar(b);
				verb("\tO char=%d ('%c')\n", b, b);
				show_stack();
				continue;

			case S: /* Subtract */
				a = pop();
				r = a - b;
				verb("\tS a=%d b=%d\n", a, b);
				break;

			case H: /* Halibut (roll) */
				roll(b);
				verb("\tH n=%d\n", b);
				show_stack();
				continue;
			}
			break;

		case A: /* next Address push */
			r = Line + 1;
			verb("\tA\n");
			break;

		case I: /* Input */
			r = getchar();
			if (r == EOF)
				r = -1;
			verb("\tI char=%d ('%c')\n", r, r);
			break;

		case N: /* Number accumulate */
			In_number = 1;
			Number = 0;
			verb("\t[N -> num=0]\n");
			continue;
		}
		push(r);
		show_stack();
	}

	return ++Line;
}

void
read_run_program(const char *	file,
		 FILE *		fp)
{
	buf_t	*program, *line;
	eta_t	max_line;

#define LINE(n) (((buf_t **)program->buf)[n])

	/*
	 * Note: We always add a dummy zeroth line, which is empty.
	 */
	File = file;
	program = buf_alloc();
	line = NULL;
	do {
		buf_push(program, (const byte_t *)&line, sizeof(line));
	} while ((line = read_line(fp)) != NULL);

	/*
	 * Now execute the program.
	 */
	Stack = buf_alloc();
	Line = 1;
	max_line = (eta_t)(program->len / sizeof(buf_t *));
	while (Line > 0 && Line < max_line) {
		Line = run_line(LINE(Line));
		if (Line < 0 || Line > max_line)
			error("address %d invalid (max %d)", Line, max_line);
	}

	/*
	 * Now free the program.
	 */
	buf_free(Stack);
	for (Line = 1; Line < max_line; Line++)
		buf_free(LINE(Line));
	buf_free(program);
}

/*
 * Outputs the correct N through E sequence for the given number.
 */
void
output_number(int	n)
{
	char	buffer[33];	/* For base 2 this would be enough */
	char	*bp = buffer + sizeof(buffer);

	*--bp = '\0';
	while (n) {
		*--bp = eta_name(n % 7);
		n /= 7;
	}
	printf("N%sE\n", bp);
}

void
output_string(const char *	s)
{
	const char *es = s + strlen(s);

	while (es >= s)
		output_number(*es--);
}

int
main(int		argc,
     char *		argv[])
{
	FILE	*fp;
	int	c, run = 1;

	init_conv();

	while ((c = getopt(argc, argv, "vN:S:")) >= 0) {
		switch (c) {
		case 'v':
			Verbose++;
			break;
		case 'N':
			output_number(atoi(optarg));
			run = 0;
			break;
		case 'S':
			output_string(optarg);
			run = 0;
			break;
		default:
			fprintf(stderr, "usage: eta [-v[v[v]]] [-N num] "
				"[-S str] [files...]\n");
			exit(1);
		}
	}
	argc -= optind;
	argv += optind;

	if (!argc && run) {
		read_run_program("stdin", stdin);
		return 0;
	}

	for (; argc--; argv++) {
		if ((fp = fopen(*argv, "r")) == NULL) {
			fprintf(stderr, "ETA: Cannot read file \"%s\"\n",
				*argv);
			exit(1);
		}
		read_run_program(*argv, fp);
		fclose(fp);
	}
	
	return 0;
}
