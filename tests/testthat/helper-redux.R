redis_cmds <- redis_api(list(command = identity))

REDIS_VERSION <- tryCatch(
  redis_version(hiredis()),
  error = function(e) numeric_version("0.0.0"))
REDIS_HOST <- redis_config()$host
REDIS_PORT <- redis_config()$port

skip_if_cmd_unsupported <- function(cmd) {
  if (cmd_since[[cmd]] <= REDIS_VERSION) {
    return()
  }
  if (REDIS_VERSION == numeric_version("0.0.0")) {
    testthat::skip("Redis is not available")
  }
  testthat::skip(
    sprintf("command %s not supported in server redis version", cmd))
}
