## These are the low-level commands for interfacing with Redis;
## creating pointers and interacting with them directly happens in
## this file and this file only.  Nothing here should be directly used
## from user code; see the functions in connection.R for what to use.
##' @importFrom RedisAPI redis_config
redis_connect <- function(...) {
  config <- RedisAPI::redis_config(...)
  if (config$scheme == "redis") {
    ptr <<- redis_connect_tcp(config$host, config$port)
  } else {
    ptr <<- redis_connect_unix(config$path)
  }
  if (!is.null(config$password)) {
    redis_command(ptr, c("AUTH", config$password))
  }
  if (!is.null(config$db)) {
    redis_command(ptr, c("SELECT", config$db))
  }
  ptr
}

redis_connect_tcp <- function(host, port) {
  .Call(Credux_redis_connect, host, as.integer(port), PACKAGE="redux")
}

redis_connect_unix <- function(path) {
  .Call(Credux_redis_connect_unix, path, PACKAGE="redux")
}

redis_command <- function(ptr, command) {
  .Call(Credux_redis_command, ptr, command, PACKAGE="redux")
}

redis_pipeline <- function(ptr, list) {
  .Call(Credux_redis_pipeline, ptr, list, PACKAGE="redux")
}

redis_subscribe <- function(ptr, channel, callback, envir) {
  ## This actually needs to depend on the sort of error.  Don't
  ## respond based on
  ##   _redis connection errors_
  ## because those we should just not go any further on.  But to get
  ## that working I'd need to work out how to raise classed errors
  ## from C, and that's going to require some decent toxiproxy testing
  ## too.
  on.exit(.Call(Credux_redis_unsubscribe, ptr, channel))
  .Call(Credux_redis_subscribe, ptr, channel, callback, envir)
  invisible()
}
