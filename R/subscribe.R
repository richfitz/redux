subscribe2 <- function(ptr, channel, transform, terminate, envir,
                       collect=TRUE, n=Inf) {
  collector <- make_collector(collect)
  callback <- make_callback(transform, terminate, collector$add, n)
  redis_subscribe(ptr, channel, callback, envir)
  collector$get()
}

make_collector <- function(collect=TRUE) {
  if (collect) {
    vals <- list()
    add <- function(x) {
      vals <<- c(vals, list(x))
      invisible(NULL)
    }
  } else {
    vals <- NULL
    add <- function(x) {
    }
  }
  list(add=add, get=function() vals)
}

make_counter <- function() {
  i <- 0L
  function() {
    i <<- i + 1L
    i
  }
}

make_callback <- function(transform, terminate, collector, n) {
  transform <- check_fun(transform,  identity)
  terminate <- check_fun(terminate,  function(x) FALSE)
  collector <- check_fun(collector,  make_collector(FALSE))
  counter <- make_counter()
  function(x) {
    x <- transform(x)
    collector(x)
    counter() >= n || terminate(x)
  }
}

check_fun <- function(fun, default) {
  if (is.null(fun)) {
    default
  } else {
    fun
  }
}
