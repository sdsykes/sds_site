ETA	= hello.c.eta maths_simple.c.eta recursion.c.eta getchar.c.eta loops.c.eta loops_nested.c.eta atoi.c.eta array.c.eta \
          strcpy.c.eta strlen.c.eta strcmp.c.eta factors.c.eta addressof.c.eta dhry.c.eta goto.c.eta subscript.c.eta \
          sizeof.c.eta strchr.c.eta memset.c.eta primes.c.eta sizeof2.c.eta array2.c.eta

all:	$(ETA)

$(ETA)	: %.eta: % 
	../c.sh $<

test	: all
	@for i in $(ETA); do ../sseta $$i; done

clean	:
	rm -f *.rr *.rro *.eta *.compiled
