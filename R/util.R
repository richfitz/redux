vcapply <- function(X, FUN, ...) {
  vapply(X, FUN, character(1), ...)
}
viapply <- function(X, FUN, ...) {
  vapply(X, FUN, integer(1), ...)
}
vlapply <- function(X, FUN, ...) {
  vapply(X, FUN, logical(1), ...)
}
vnapply <- function(X, FUN, ...) {
  vapply(X, FUN, numeric(1), ...)
}

Sys_getenv <- function(x, unset=NULL) {
  assert_scalar_character(x)
  ret <- Sys.getenv(x, NA_character_)
  if (is.na(ret)) unset else ret
}

drop_null <- function(x) {
  x[!vlapply(x, is.null)]
}

modify_list <- function(x, val, name=deparse(substitute(x))) {
  warn_unknown(name, val, names(x))
  modifyList(x, val)
}

capture_args <- function(f, name) {
  args <- capture.output(args(f))
  sub("function ", name,
      paste0(paste(args[-length(args)], collapse="\n"), "\n"))
}
