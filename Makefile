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

vignettes: vignettes/plant.Rmd
	${RSCRIPT} -e 'library(methods); devtools::build_vignettes()'

.PHONY: all compile_dll doc clean test install vignettes
