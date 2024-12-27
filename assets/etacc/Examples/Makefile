ETA	= pig.c.eta

all:	$(ETA)

$(ETA)	: %.eta: % 
	../c.sh $<

test	: all
	@for i in $(ETA); do ../sseta $$i; done

clean	:
	rm -f *.rr *.rro *.eta *.compiled
