rand_str <- function(len=8, prefix="") {
  paste0(prefix,
         paste(sample(c(LETTERS, letters, 0:9), len), collapse=""))
}

redis_status <- function(x) {
  class(x) <- "redis_status"
  x
}

is_OK <- function() {
  function(x) {
    expectation(identical(x, redis_status("OK")),
                paste0("redis status is not OK"),
                paste0("redis status is OK"))
  }
}
