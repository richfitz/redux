assert_match_value <- function(x, choices, name = deparse(substitute(x))) {
  assert_scalar_character(x, name = name)
  if (!(x %in% choices)) {
    stop(sprintf("%s must be one of %s", name,
                 paste(dQuote(choices), collapse = ", ")))
  }
}

assert_match_value_or_null <- function(x, choices,
                                       name = deparse(substitute(x))) {
  if (!is.null(x)) {
    assert_scalar_character(x)
    if (!(x %in% choices)) {
      stop(sprintf("%s must be one of %s", name,
                   paste(dQuote(choices), collapse = ", ")))
    }
  }
}

assert_scalar <- function(x, name = deparse(substitute(x))) {
  if (length(x) != 1L) {
    stop(sprintf("%s must be a scalar", name), call. = FALSE)
  }
}

assert_length <- function(x, n, name = deparse(substitute(x))) {
  if (length(x) != n) {
    stop(sprintf("%s must be length %d", name, n), call. = FALSE)
  }
}

assert_character <- function(x, name = deparse(substitute(x))) {
  if (!is.character(x)) {
    stop(sprintf("%s must be character", name), call. = FALSE)
  }
}

assert_logical <- function(x, name = deparse(substitute(x))) {
  if (!is.logical(x)) {
    stop(sprintf("%s must be logical", name), call. = FALSE)
  }
}

assert_is <- function(x, class, name = deparse(substitute(x))) {
  if (!inherits(x, class)) {
    stop(sprintf("%s must be a %s", name,
                 paste(class, collapse = "/")), call. = FALSE)
  }
}

assert_scalar_character <- function(x, name = deparse(substitute(x))) {
  assert_scalar(x, name)
  assert_character(x, name)
  assert_nonmissing(x, name)
}

assert_scalar_logical <- function(x, name = deparse(substitute(x))) {
  assert_scalar(x, name)
  assert_logical(x, name)
  assert_nonmissing(x, name)
}

assert_scalar_or_null <- function(x, name = deparse(substitute(x))) {
  if (!is.null(x)) {
    assert_scalar(x, name)
  }
}

assert_scalar_or_raw <- function(x, name = deparse(substitute(x))) {
  if (length(x) != 1L && !is.raw(x)) {
    stop(sprintf("%s must be a scalar", name), call. = FALSE)
  }
}

assert_raw <- function(x, name = deparse(substitute(x))) {
  if (!is.raw(x)) {
    stop(sprintf("'%s' must be raw", name), call. = FALSE)
  }
}

assert_length_or_null <- function(x, n, name = deparse(substitute(x))) {
  if (!is.null(x)) {
    assert_length(x, n, name)
  }
}

assert_named <- function(x,
                         empty_can_be_unnamed = TRUE,
                         unique_names = TRUE,
                         name = deparse(substitute(x))) {
  nx <- names(x)
  if (is.null(nx) || any(!nzchar(nx))) {
    if (length(x) > 0 || !empty_can_be_unnamed) {
      stop(sprintf("%s must be named", name), call. = FALSE)
    }
  } else if (unique_names && any(duplicated(nx))) {
    stop(sprintf("%s must have unique names", name), call. = FALSE)
  }
}

## Different treatment of length for raw vectors.
length2 <- function(x) {
  if (is.raw(x)) 1L else length(x)
}

assert_scalar2 <- function(x, name = deparse(substitute(x))) {
  if (length2(x) != 1L) {
    stop(sprintf("%s must be a scalar", name), call. = FALSE)
  }
}
assert_scalar_or_null2 <- function(x, name = deparse(substitute(x))) {
  if (!is.null(x)) {
    assert_scalar2(x, name)
  }
}
assert_length_or_null2 <- function(x, n, name = deparse(substitute(x))) {
  if (!is.null(x)) {
    assert_length2(x, n, name)
  }
}
assert_length2 <- function(x, n, name = deparse(substitute(x))) {
  if (length2(x) != n) {
    stop(sprintf("%s must be length %d", name, n), call. = FALSE)
  }
}

assert_nonmissing <- function(x, name = deparse(substitute(x))) {
  if (any(is.na(x))) {
    stop(sprintf("%s must not be NA", name), call. = FALSE)
  }
}

## Warn if keys are found in an object that are not in a known set.
warn_unknown <- function(name, defn, known) {
  unknown <- setdiff(names(defn), known)
  if (length(unknown) > 0) {
    msg <- sprintf("Unknown fields in %s: %s",
                   name, paste(unknown, collapse = ", "))
    warning(msg, immediate. = TRUE, call. = FALSE)
  }
}
