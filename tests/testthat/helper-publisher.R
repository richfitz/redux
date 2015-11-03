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
  res <- system2("./pub_runif.R", filename, wait=FALSE, stderr=log)
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

PSKILL_SUCCESS <- tools::pskill(Sys.getpid(), 0)
pid_exists <- function(pid) {
  tools::pskill(pid, 0) == PSKILL_SUCCESS
}
