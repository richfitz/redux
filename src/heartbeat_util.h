#ifndef REDUX_HEARTBEAT_UTIL_H
#define REDUX_HEARTBEAT_UTIL_H

#include <stdbool.h>
#include <R.h>
#include <Rinternals.h>

char * string_duplicate_c(const char * x);
const char * scalar_string(SEXP x);
bool scalar_logical(SEXP x);
int scalar_integer(SEXP x);
double scalar_numeric(SEXP x);

#endif
