##' Create a Redis API object.  This function is designed to be used
##' from other packages, and not designed to be used directly by
##' users.
##'
##' @title Create a Redis API object
##'
##' @param x An object that defines at least the function
##'   \code{command} capable of processing commands in the appropriate
##'   form.
##'  
##' @param version Version of the Redis API to generate.  If given as
##'   a numeric version (or something that can be coerced into one.
##'   If given as \code{TRUE}, then we query the Redis server for its
##'   version and generate only commands supported by the server.
##'
##' @importFrom R6 R6Class
##' @export
redis_api <- function(x, version = NULL) {
  R6_redis_api$new(x, version)
}

R6_redis_api <- R6::R6Class(
  "redis_api",
  lock_class = FALSE,
  lock_objects = FALSE,

  private = list(
    .pipeline = NULL,
    .subscribe = NULL,
    .version = NULL
  ),

  public = list(
    config = NULL,
    type = NULL,
    reconnect = NULL,
    command = NULL,

    initialize = function(x, version) {
      self$command <- hiredis_function("command", x)
      self$config <- hiredis_function("config", x)
      self$reconnect <- hiredis_function("reconnect", x)
      private$.pipeline <- hiredis_function("pipeline", x)
      private$.subscribe <- hiredis_function("subscribe", x)
      self$type <- function() attr(x, "type", exact = TRUE)
      redis <- filter_redis_commands(redis_commands(self$command),
                                     version, self$command)
      for (el in names(redis)) {
        self[[el]] <- redis[[el]]
      }

      lockEnvironment(self)
    },

    pipeline = function(..., .commands = list(...)) {
      ret <- private$.pipeline(.commands)
      if (!is.null(names(.commands))) {
        names(ret) <- names(.commands)
      }
      ret
    },

    subscribe = function(channel, transform = NULL, terminate = NULL,
                       collect = TRUE, n = Inf, pattern = FALSE,
                       envir = parent.frame()) {
      assert_scalar_logical(pattern)
      collector <- make_collector(collect)
      callback <- make_callback(transform, terminate, collector$add, n)
      private$.subscribe(channel, pattern, callback, envir)
      collector$get()
    },

    version = function() {
      if (is.null(private$.version)) {
        private$.version <- parse_info(self$command("INFO"))$redis_version
      }
      private$.version
    }
  ))

## Functions used to build the redis_api interface or to run it:
hiredis_function <- function(name, obj, required = FALSE) {
  f <- obj[[name]]
  if (is.null(f)) {
    force(name)
    if (required) {
      stop(sprintf("Interface function %s required", name))
    }
    ## This was required for RcppRedis but I removed that.
    f <- function(...) {
      stop(sprintf("%s is not supported with the %s interface",
                   name, attr(obj, "type")))
    }
  }
  f
}

filter_redis_commands <- function(x, version, command = NULL) {
  if (is.character(version)) {
    version <- numeric_version(version)
  } else if (isTRUE(version)) {
    if (!is.function(command)) {
      stop("No redis connection to get version from")
    }
    version <- parse_info(command("INFO"))$redis_version
  }
  if (inherits(version, "numeric_version")) {
    x <- x[cmd_since[names(x)] <= version]
  }
  x
}

cmd_interleave <- function(a, b, c = NULL) {
  assert_length2(b, length2(a))
  arg3 <- !is.null(c)
  if (arg3) {
    assert_length2(c, length2(a))
  }
  convert <- function(x) {
    if (is.logical(x)) {
      as.character(as.integer(x))
    } else if (is.list(x)) {
      x
    } else if (is.raw(x)) {
      list(x)
    } else {
      as.character(x)
    }
  }
  join <- function(a, b, c = NULL) {
    c(rbind(a, b, c))
  }
  a <- convert(a)
  b <- convert(b)
  if (arg3) {
    c <- convert(c)
  }
  if (is.character(a) && is.character(b) && (!arg3 || is.character(c))) {
    join(a, b, c)
  } else if (arg3) {
    join(as.list(a), as.list(b), as.list(c))
  } else {
    join(as.list(a), as.list(b))
  }
}

cmd_command <- function(cmd, value, combine) {
  n <- length(value)
  if (n == 0L) {
    NULL
  } else if (n == 1L || combine) {
    list(cmd, value)
  } else {
    cmd_interleave(rep_len(cmd, length(value)), value)
  }
}

##' @export
print.redis_commands <- function(x, ...) {
  cat(sprintf("<redis_commands>\n"))
  cat("  Redis commands:\n")
  print_methods(x, "^[A-Z]")
}

##' @export
print.redis_api <- function(x, ...) {
  cat(sprintf("<%s>\n", class(x)[[1]]))
  cat("  Redis commands:\n")
  print_methods(x, "^[A-Z]")
  cat("  Other public methods:\n")
  print_methods(x, "^[a-z]")
}

print_methods <- function(x, pattern) {
  cat(paste0("    ", sort(ls(x, pattern = pattern)), ": function\n",
             collapse = ""))
}

## NOTE: Used by redis_connection, rlite_connection
##' @export
print.redis_connection <- function(x, ...) {
  cat(sprintf("<redis_connection[%s]>:\n", attr(x, "type", exact = TRUE)))
  for (i in names(x)) {
    cat(sprintf("  - %s", capture_args(x[[i]], i)))
  }
  invisible(x)
}
