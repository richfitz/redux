## Helpers that will be used by both redux and rrlite (possibly after
## translation).
skip_if_no_redis <- function() {
  if (redis_available()) {
    return()
  }
  testthat::skip("Redis is not available")
}

skip_if_not_isolated_redis <- function() {
  ## TODO: set this so that some tests can be skipped unless I flag
  ## that we're allowed to do destructive things.
  return()
}

skip_if_no_scan <- function(r) {
  if (!inherits(try(r$SCAN(1, COUNT = 1), silent = TRUE), "try-error")) {
    return()
  }
  testthat::skip("SCAN not implemented")
}

skip_if_no_info <- function(r) {
  if (!inherits(try(r$INFO(), silent = TRUE), "try-error")) {
    return()
  }
  testthat::skip("INFO not implemented")
}

skip_if_no_time <- function(r) {
  if (!inherits(try(r$TIME(), silent = TRUE), "try-error")) {
    return()
  }
  testthat::skip("TIME not implemented")
}

redis_status <- function(x) {
  class(x) <- "redis_status"
  x
}

rand_str <- function(len = 8, prefix = "") {
  paste0(prefix,
         paste(sample(c(LETTERS, letters, 0:9), len), collapse = ""))
}

vcapply <- function(X, FUN, ...) {
  vapply(X, FUN, character(1), ...)
}

sys_setenv <- function(...) {
  vars <- names(list(...))
  prev <- vapply(vars, Sys.getenv, "", NA_character_)
  Sys.setenv(...)
  prev
}

sys_resetenv <- function(old) {
  i <- is.na(old)
  if (any(i)) {
    Sys.unsetenv(names(old)[i])
  }
  if (any(!i)) {
    do.call("Sys.setenv", as.list(old[!i]))
  }
}
