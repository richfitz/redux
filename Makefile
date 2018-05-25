PACKAGE := $(shell grep '^Package:' DESCRIPTION | sed -E 's/^Package:[[:space:]]+//')
RSCRIPT = Rscript --no-init-file

all: compile_dll

compile_dll:
	${RSCRIPT} -e 'devtools::compile_dll()'

test:
	${RSCRIPT} -e 'library(methods); devtools::test()'

test_leaks: .valgrind_ignore
	R -d 'valgrind --leak-check=full --suppressions=.valgrind_ignore' -e 'devtools::test()'

.valgrind_ignore:
	R -d 'valgrind --leak-check=full --gen-suppressions=all --log-file=$@' -e 'library(testthat)'
	sed -i.bak '/^=/ d' $@
	rm -f $@.bak

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
	R CMD build .

check:
	_R_CHECK_CRAN_INCOMING_=FALSE make check_all

check_all:
	${RSCRIPT} -e "rcmdcheck::rcmdcheck(args = c('--as-cran', '--no-manual'))"

clean:
	rm -f src/*.o src/*.so

vignettes_src/redux.Rmd: vignettes_src/redux.R
	${RSCRIPT} -e 'library(sowsear); sowsear("$<", output="$@")'

vignettes/redux.Rmd: vignettes_src/redux.Rmd
	cd vignettes_src && ${RSCRIPT} -e 'knitr::knit("redux.Rmd")'
	mv vignettes_src/redux.md $@
	sed -i.bak 's/[[:space:]]*$$//' $@
	rm -f $@.bak

vignettes_src/low_level.Rmd: vignettes_src/low_level.R
	${RSCRIPT} -e 'library(sowsear); sowsear("$<", output="$@")'

vignettes/low_level.Rmd: vignettes_src/low_level.Rmd
	cd vignettes_src && ${RSCRIPT} -e 'knitr::knit("low_level.Rmd")'
	mv vignettes_src/low_level.md $@
	sed -i.bak 's/[[:space:]]*$$//' $@
	rm -f $@.bak

vignettes_install: vignettes/redux.Rmd vignettes/low_level.Rmd
	${RSCRIPT} -e 'library(methods); devtools::build_vignettes()'

vignettes:
	rm -f vignettes/redux.Rmd vignettes/low_level.Rmd
	make vignettes_install

pkgdown:
	${RSCRIPT} -e "library(methods); pkgdown::build_site()"

website: pkgdown
	./update_web.sh

.PHONY: all compile_dll doc clean test install vignettes
