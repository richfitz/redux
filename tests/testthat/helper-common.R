## Helpers that will be used by both redux and rrlite (possibly after
## translation).
skip_if_no_redis <- function() {
  if (redis_available()) {
    return()
  }
  skip("Redis is not available")
}

skip_if_no_scan <- function(r) {
  if (!inherits(try(r$SCAN(1, COUNT=1), silent=TRUE), "try-error")) {
    return()
  }
  skip("SCAN not implemented")
}

skip_if_no_info <- function(r) {
  if (!inherits(try(r$INFO(), silent=TRUE), "try-error")) {
    return()
  }
  skip("INFO not implemented")
}

skip_if_no_time <- function(r) {
  if (!inherits(try(r$TIME(), silent=TRUE), "try-error")) {
    return()
  }
  skip("TIME not implemented")
}

redis_status <- function(x) {
  class(x) <- "redis_status"
  x
}

rand_str <- function(len=8, prefix="") {
  paste0(prefix,
         paste(sample(c(LETTERS, letters, 0:9), len), collapse=""))
}

vcapply <- function(X, FUN, ...) {
  vapply(X, FUN, character(1), ...)
}
