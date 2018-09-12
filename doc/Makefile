NAME=cheby-ug

all: $(NAME).pdf

$(NAME).xml: $(NAME).txt srcs/counter.cheby
	asciidoctor -v -d book -b docbook $<

$(NAME).pdf: $(NAME).xml
	a2x -f pdf $<

clean:
	$(RM) $(NAME).xml $(NAME).pdf
