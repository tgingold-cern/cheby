NAME=cheby-ug
CHEBY=../proto/cheby.py

all: $(NAME).pdf

srcs/counter.vhdl: srcs/counter.cheby
	$(CHEBY) --gen-hdl=$@ -i $<

srcs/counter_entity.vhdl: srcs/counter.vhdl
	sed -n -e '/^entity/,/^end/p' < $< > $@

srcs/counter.h: srcs/counter.cheby
	$(CHEBY) --gen-c=$@ -i $<

$(NAME).xml: $(NAME).txt srcs/counter.cheby srcs/counter_entity.vhdl srcs/counter.h
	asciidoctor -v -d book -b docbook $<

$(NAME).pdf: $(NAME).xml
	a2x -f pdf $<

clean:
	$(RM) $(NAME).xml $(NAME).pdf
