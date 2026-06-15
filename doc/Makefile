NAME=cheby-ug
CHEBY=../proto/cheby-local.py

all: $(NAME).pdf

srcs/counter.vhdl: srcs/counter.cheby
	$(CHEBY) --gen-hdl=$@ -i $<

srcs/counter_entity.vhdl: srcs/counter.vhdl
	sed -n -e '/^entity/,/^end/p' < $< > $@

srcs/counter.h: srcs/counter.cheby
	$(CHEBY) --gen-c=$@ -i $<

srcs/counter.adoc: srcs/counter.cheby
	$(CHEBY) --doc=asciidoc --gen-doc=$@ -i $<

srcs/counter-reindent.adoc: srcs/counter.adoc
	sed -e '/^=/s/^=/==/' < $< > $@

$(NAME).xml: $(NAME).txt cheby-extensions.adoc srcs/counter.cheby srcs/counter_entity.vhdl srcs/counter.h srcs/counter-reindent.adoc
	asciidoctor -v -d book -b docbook -a version=$$(python3 -c "import sys; sys.path.insert(0, '../proto'); from cheby import __version__; print(__version__)") -a revdate="$$(git log -1 --format=%cd --date=short)" $<

$(NAME).pdf: $(NAME).xml
	a2x -f pdf $<

clean:
	$(RM) $(NAME).xml $(NAME).pdf
	$(RM) srcs/counter.vhdl srcs/counter_entity.vhdl srcs/counter.h
	$(RM) srcs/counter.adoc srcs/counter-reindent.adoc
