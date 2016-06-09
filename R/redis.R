## These are the low-level commands for interfacing with Redis;
## creating pointers and interacting with them directly happens in
## this file and this file only.  Nothing here should be directly used
## from user code; see the functions in connection.R for what to use.
redis_connect <- function(config) {
  if (config$scheme == "redis") {
    ptr <- redis_connect_tcp(config$host, config$port)
  } else {
    ptr <- redis_connect_unix(config$path)
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
  .Call(Credux_redis_connect, host, as.integer(port))
}

redis_connect_unix <- function(path) {
  .Call(Credux_redis_connect_unix, path)
}

redis_command <- function(ptr, command) {
  .Call(Credux_redis_command, ptr, command)
}

redis_pipeline <- function(ptr, list) {
  .Call(Credux_redis_pipeline, ptr, drop_null(list))
}

redis_subscribe <- function(ptr, channel, pattern, callback, envir) {
  ## This actually needs to depend on the sort of error.  Don't
  ## respond based on
  ##   _redis connection errors_
  ## because those we should just not go any further on.  But to get
  ## that working I'd need to work out how to raise classed errors
  ## from C, and that's going to require some decent toxiproxy testing
  ## too.
  ##
  ## Also, while we check all over the show that pattern needs to be a
  ## scalar logical, we don't want to trigger the on.exit call if the
  ## failure was due to the pattern being incorrect (this is actually
  ## slightly worse than failures in general (say callback not a
  ## function) because incorrect access of a NULL could crash R).
  ##
  ## What would be ideal would be to write something into an
  ## environment (even the one passed in) saying that subscription had
  ## started and then switching on that.  But that's a big hassle for
  ## a difficult corner case.
  on.exit(.Call(Credux_redis_unsubscribe, ptr, channel, pattern))
  .Call(Credux_redis_subscribe, ptr, channel, pattern, callback, envir)
  invisible()
}
