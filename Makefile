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
	R CMD build .

check:
	_R_CHECK_CRAN_INCOMING_=FALSE make check_all

check_all:
	${RSCRIPT} -e "rcmdcheck::rcmdcheck(args = c('--as-cran', '--no-manual'))"

clean:
	rm -f src/*.o src/*.so

vignettes/src/redux.Rmd: vignettes/src/redux.R
	${RSCRIPT} -e 'library(sowsear); sowsear("$<", output="$@")'

vignettes/redux.Rmd: vignettes/src/redux.Rmd
	cd vignettes/src && ${RSCRIPT} -e 'knitr::knit("redux.Rmd")'
	mv vignettes/src/redux.md $@
	sed -i.bak 's/[[:space:]]*$$//' $@
	rm -f $@.bak

vignettes/src/low_level.Rmd: vignettes/src/low_level.R
	${RSCRIPT} -e 'library(sowsear); sowsear("$<", output="$@")'

vignettes/low_level.Rmd: vignettes/src/low_level.Rmd
	cd vignettes/src && ${RSCRIPT} -e 'knitr::knit("low_level.Rmd")'
	mv vignettes/src/low_level.md $@
	sed -i.bak 's/[[:space:]]*$$//' $@
	rm -f $@.bak

vignettes_install: vignettes/redux.Rmd vignettes/low_level.Rmd
	${RSCRIPT} -e 'library(methods); devtools::build_vignettes()'

vignettes:
	rm -f vignettes/redux.Rmd vignettes/low_level.Rmd
	make vignettes_install

staticdocs:
	@mkdir -p inst/staticdocs
	Rscript -e "library(methods); staticdocs::build_site()"
	rm -f vignettes/*.html
	@rmdir inst/staticdocs
website: staticdocs
	./update_web.sh

.PHONY: all compile_dll doc clean test install vignettes
