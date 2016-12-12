skip_if_no_rcppredis <- function() {
  testthat::skip_if_not_installed("RcppRedis")
  if (rcppredis_available()) {
    return()
  }
  testthat::skip("Redis is not available")
}

redis_cmds <- redis_api(list(command = identity))
