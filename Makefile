PACKAGE := $(shell grep '^Package:' DESCRIPTION | sed -E 's/^Package:[[:space:]]+//')
RSCRIPT = Rscript --no-init-file

all: compile_dll

compile_dll:
	${RSCRIPT} -e 'devtools::compile_dll()'

test:
	${RSCRIPT} -e 'library(methods); devtools::test()'

RcppR6:
	${RSCRIPT} -e "library(methods); RcppR6::RcppR6()"

attributes:
	${RSCRIPT} -e "Rcpp::compileAttributes()"

roxygen:
	@mkdir -p man
	${RSCRIPT} -e "library(methods); devtools::document()"

install:
	R CMD INSTALL .

build:
	R CMD build --no-build-vignettes .

check: build
	R CMD check --as-cran --no-manual `ls -1tr ${PACKAGE}*gz | tail -n1`
	@rm -f `ls -1tr ${PACKAGE}*gz | tail -n1`
	@rm -rf ${PACKAGE}.Rcheck

clean:
	rm -f src/*.o src/*.so
	make -C src/hiredis -f Makefile2 clean

vignettes/src/redux.Rmd: vignettes/src/redux.R
	${RSCRIPT} -e 'library(sowsear); sowsear("$<", output="$@")'

vignettes/redux.Rmd: vignettes/src/redux.Rmd
	cd vignettes/src && ${RSCRIPT} -e 'knitr::knit("redux.Rmd")'
	mv vignettes/src/redux.md $@
	sed -i.bak 's/[[:space:]]*$$//' $@
	rm -f $@.bak

vignettes_install: vignettes/redux.Rmd
	${RSCRIPT} -e 'library(methods); devtools::build_vignettes()'

vignettes:
	rm -f vignettes/redux.Rmd
	make vignettes_install

staticdocs:
	@mkdir -p inst/staticdocs
	Rscript -e "library(methods); staticdocs::build_site()"
	rm -f vignettes/*.html
	@rmdir inst/staticdocs
website: staticdocs
	./update_web.sh

.PHONY: all compile_dll doc clean test install vignettes
