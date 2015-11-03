PACKAGE := $(shell grep '^Package:' DESCRIPTION | sed -E 's/^Package:[[:space:]]+//')
RSCRIPT = Rscript --no-init-file

all: compile_dll

compile_dll:
	Rscript -e 'devtools::compile_dll()'

test:
	Rscript -e 'library(methods); devtools::test()'

RcppR6:
	Rscript -e "library(methods); RcppR6::RcppR6()"

attributes:
	Rscript -e "Rcpp::compileAttributes()"

roxygen:
	@mkdir -p man
	Rscript -e "library(methods); devtools::document()"

install:
	R CMD INSTALL .

build:
	R CMD build --no-build-vignettes .

check: build
	R CMD check --no-build-vignettes --no-manual `ls -1tr ${PACKAGE}*gz | tail -n1`
	@rm -f `ls -1tr ${PACKAGE}*gz | tail -n1`
	@rm -rf ${PACKAGE}.Rcheck

clean:
	rm -f src/*.o src/*.so

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

.PHONY: all compile_dll doc clean test install vignettes
