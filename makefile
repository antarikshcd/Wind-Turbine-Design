
OBJS =  bibliography.bib main.tex preamble.tex

main.pdf:    $(OBJS) 
	pdflatex main
	bibtex main
	pdflatex main
	pdflatex main
	
clean: 
	@echo cleaning objects, modules and executables 
	rm *.aux *.log *.synctex.gz *.out *.toc *.blg *.blb
