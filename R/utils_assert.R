assert_integer <- function(x, strict=FALSE, name=deparse(substitute(x))) {
  if (!(is.integer(x))) {
    usable_as_integer <-
      !strict && is.numeric(x) && (max(abs(as.integer(x) - x)) < 1e-8)
    if (!usable_as_integer) {
      stop(sprintf("%s must be integer", name), call.=FALSE)
    }
  }
}
assert_character <- function(x, name=deparse(substitute(x))) {
  if (!is.character(x)) {
    stop(sprintf("%s must be character", name), call.=FALSE)
  }
}

assert_scalar <- function(x, name=deparse(substitute(x))) {
  if (length(x) != 1) {
    stop(sprintf("%s must be a scalar", name), call.=FALSE)
  }
}

assert_scalar_integer <- function(x, strict=FALSE,
                                  name=deparse(substitute(x))) {
  assert_scalar(x, name)
  assert_integer(x, strict, name)
}
assert_scalar_character <- function(x, name=deparse(substitute(x))) {
  assert_scalar(x, name)
  assert_character(x, name)
}

assert_file_exists <- function(x, name=deparse(substitute(x))) {
  assert_scalar_character(x, name)
  if (!file.exists(x)) {
    stop(sprintf("The file '%s' does not exist", x), call.=FALSE)
  }
}

assert_length <- function(x, n, name=deparse(substitute(x))) {
  if (length(x) != n) {
    stop(sprintf("%s must have %d elements", name, n), call. = FALSE)
  }
}

## Related:
warn_unknown <- function(name, defn, known) {
  stop_unknown(name, defn, known, FALSE)
}

## Warn if keys are found in an object that are not in a known set.
stop_unknown <- function(name, defn, known, error=TRUE) {
  unknown <- setdiff(names(defn), known)
  if (length(unknown) > 0) {
    msg <- sprintf("Unknown fields in %s: %s",
                   name, paste(unknown, collapse=", "))
    if (error) {
      stop(msg, call.=FALSE)
    } else {
      warning(msg, immediate.=TRUE, call.=FALSE)
    }
  }
}
