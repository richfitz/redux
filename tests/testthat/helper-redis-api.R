skip_if_no_rcppredis <- function() {
  skip_if_not_installed("RcppRedis")
  if (rcppredis_available()) {
    return()
  }
  skip("Redis is not available")
}
