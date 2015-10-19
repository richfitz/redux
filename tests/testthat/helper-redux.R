is_OK <- function() {
  function(x) {
    ok <- inherits(x, "redis_status") && identical(as.character(x), "OK")
    expectation(ok,
                paste0("redis status is not OK"),
                paste0("redis status is OK"))
  }
}

rand_str <- function(len=8, prefix="") {
  paste0(prefix,
         paste(sample(c(LETTERS, letters, 0:9), len), collapse=""))
}

## from rrqueue:
time_checker <- function(timeout) {
  t0 <- Sys.time()
  timeout <- as.difftime(timeout, units="secs")
  function() {
    Sys.time() - t0 > timeout
  }
}

start_publisher <- function(channel, dt=0.02) {
  filename <- tempfile("redux_")
  writeLines(c(channel, dt), filename)
  log <- tempfile("redux_")
  Sys.setenv("R_TESTS" = "")
  system2("./rand.R", filename, wait=FALSE, stderr=log)
  t <- time_checker(1.0)
  pid <- NULL
  while(!t()) {
    if (file.exists(log)) {
      dat <- readLines(log, 1L)
      if (length(dat) == 1L) {
        pid <- dat
        break
      }
      Sys.sleep(.05)
    }
  }
  if (length(pid) != 1L || !pid_exists(pid)) {
    stop("Didn't get publisher started")
  }
  filename
}

redis_status <- function(x) {
  class(x) <- "redis_status"
  x
}

PSKILL_SUCCESS <- tools::pskill(Sys.getpid(), 0)
pid_exists <- function(pid) {
  tools::pskill(pid, 0) == PSKILL_SUCCESS
}

vcapply <- function(X, FUN, ...) {
  vapply(X, FUN, character(1), ...)
}
