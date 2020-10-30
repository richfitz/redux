##' Create a set of valid Redis configuration options.
##'
##' Valid arguments here are:
##'
##' \describe{
##'
##' \item{\code{url}}{The URL for the Redis server.  See examples.
##' (default: Look up environment variable \code{REDIS_URL} or
##' \code{NULL}).}
##'
##' \item{\code{host}}{The hostname of the Redis server. (default:
##' \code{127.0.0.1}).}
##'
##' \item{\code{port}}{The port of the Redis server. (default: 6379).}
##'
##' \item{\code{path}}{The path for a Unix socket if connecting that way.}
##'
##' \item{\code{password}}{The Redis password (for use with
##' \code{AUTH}).  This will be stored in \emph{plain text} as part of
##' the Redis object.  (default: \code{NULL}).}
##'
##' \item{\code{db}}{The Redis database number to use (for use with
##' \code{SELECT}.  Do not use in a redis clustering context.
##' (default: \code{NULL}; i.e., don't switch).}
##'
##' }
##'
##' The way that configuration options are resolved follows the design
##' for redis-rb very closely.
##'
##' \enumerate{
##'
##' \item{First, look up (and parse if found) the \code{REDIS_URL}
##' environment variable and override defaults with that.}
##'
##' \item{Any arguments given (\code{host}, \code{port},
##' \code{password}, \code{db}) override values inferred from the url
##' or defaults.}
##'
##' \item{If \code{path} is given, that overrides the
##' \code{host}/\code{port} settings and a socket connection will be
##' used.}
##' }
##'
##' @examples
##' # default config:
##' redis_config()
##'
##' # set values
##' redis_config(host = "myhost")
##'
##' # url settings:
##' redis_config(url = "redis://:p4ssw0rd@@myhost:32000/2")
##'
##' # override url settings:
##' redis_config(url = "redis://myhost:32000", port = 31000)
##' redis_config(url = "redis://myhost:32000", path = "/tmp/redis.conf")
##' @title Redis configuration
##' @param ... See Details
##' @param config A list of options, to use in place of \code{...}
##' @export
redis_config <- function(..., config = list(...)) {
  ## TODO: consider allowing case where where:
  ##   1 arg and is unnamed character (assume host)
  ##   2 arg and char/int, unnamed (assume host/port?)
  defaults <- list(
                url = Sys_getenv("REDIS_URL", NULL),
                scheme = "redis",
                host = Sys_getenv("REDIS_HOST", "127.0.0.1"),
                port = as.integer(Sys_getenv("REDIS_PORT", 6379L)),
                path = NULL,
                password = NULL,
                db = NULL)
  dots <- list(...)
  if (length(dots) > 0L && !identical(dots, config)) {
    warning("Ignoring dots in favour of config")
  }

  if (inherits(config, "redis_config")) {
    return(config)
  } else if (length(config) == 1 && inherits(config[[1]], "redis_config")) {
    ## TODO: test
    return(config[[1]])
  } else if (length(config) > 0L && is.list(config[[1L]])) {
    if (length(config) != 1L) {
      stop("Invalid configuration")
    }
    config <- config[[1]]
  } else if (is.null(config)) {
    config <- list()
  }

  if (length(config) > 0L &&
      (is.null(names(config)) || any(names(config) == ""))) {
    stop("All config elements must be named")
  }
  len <- lengths(config)
  is_null <- vlapply(config, is.null)
  err <- !is_null & len != 1L
  if (any(err)) {
    stop(sprintf("All config elements must be scalar (err on %s)",
                 paste(names(err), collapse = ", ")))
  }

  ## TODO: assert knowns, assert named, test this.
  ## Not sure about this; should it be a warning perhaps?
  config$scheme <- NULL

  given <- function(x) x %in% names(config)

  ## Modify *defaults* if a URL was given (directly or via the
  ## environment variable).  The argument overrides the environment
  ## variable.  The drop_null here is important as it means that we'll
  ## use the defaults if the url doesn't imply a parameter.
  if (!given("url")) {
    config$url <- Sys_getenv("REDIS_URL", NULL)
  }
  if (given("path")) {
    config$scheme <- "unix"
  }

  if (given("url")) {
    url <- drop_null(parse_redis_url(config$url))
    defaults <- modify_list(defaults, url)
  }
  ret <- modify_list(defaults, drop_null(config))[names(defaults)]

  if (given("path")) {
    ret["host"] <- ret["port"] <- list(NULL)
  }

  if (!given("url") && ret$scheme == "redis") {
    given2 <- function(x) !identical(config[[x]], defaults[[x]])
    ## Build the URL by stapling together the components that do not
    ## differ from the defaults but keeping the hostname/port always.
    pw <- if (given2("password")) paste0(ret$password, "@") else ""
    db <- if (given2("password")) paste0("/", ret$db)       else ""
    ret$url <- sprintf("redis://%s%s:%s%s", pw, ret$host, ret$port, db)
  }

  class(ret) <- "redis_config"
  ret
}

##' @export
print.redis_config <- function(x, ...) {
  f <- function(x) if (is.null(x)) "" else as.character(x)
  cat("Redis configuration:\n")
  cat(paste(sprintf("  - %s: %s\n", names(x), vcapply(x, f)), collapse = ""))
}

##' @export
print.redis_status <- function(x, ...) {
  cat(sprintf("[Redis: %s]\n", x))
}

##' Parse a Redis URL
##' @title Parse Redis URL
##' @param url A URL to parse
##' @export
##'
parse_redis_url <- function(url) {
  clean <- function(x, integer = FALSE) {
    if (x == "") {
      NULL
    } else if (integer) {
      as.integer(x)
    } else {
      x
    }
  }
  ## TODO: parse unix:// scheme
  assert_scalar_character(url)
  url <- URLdecode(url)
  re <- "^([a-z]+://)?(:.+?@)?([[:alnum:]._-]+)(:[0-9]+)?(/.+)?$"
  if (grepl(re, url)) {
    list(
      scheme = clean(sub("://$", "", sub(re, "\\1", url))),
      password = clean(gsub("(^:)|(@$)", "", sub(re, "\\2", url))),
      host = clean(sub(re, "\\3", url)),
      port = clean(sub("^:", "", sub(re, "\\4", url)), TRUE),
      db   = clean(sub("^/", "", sub(re, "\\5", url)), TRUE))
  } else {
    stop("Failed to parse URL")
  }
}
