NAME=cheby-ug
CHEBY=../proto/cheby.py
BUNDLER=bundle

srcs/counter.vhdl: srcs/counter.cheby
	$(CHEBY) --gen-hdl=$@ -i $<

srcs/counter_entity.vhdl: srcs/counter.vhdl
	sed -n -e '/^entity/,/^end/p' < $< > $@

srcs/counter.h: srcs/counter.cheby
	$(CHEBY) --gen-c=$@ -i $<

srcs/counter.md: srcs/counter.cheby
	$(CHEBY) --doc=md --gen-doc=$@ -i $<

srcs/counter-reindent.md: srcs/counter.md
	sed -e '/^=/s/^=/==/' < $< > $@

$(NAME).pdf: $(NAME).txt srcs/counter.cheby srcs/counter_entity.vhdl srcs/counter.h srcs/counter-reindent.md
	$(BUNDLER) exec asciidoctor-pdf -d book $<

install:
	$(BUNDLER) install

all: $(NAME).pdf

clean:
	$(RM) srcs/*.vhdl srcs/*.h srcs/*.md
	$(RM) $(NAME).pdf
