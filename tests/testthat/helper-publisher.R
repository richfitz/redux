## from rrqueue:
time_checker <- function(timeout) {
  t0 <- Sys.time()
  timeout <- as.difftime(timeout, units = "secs")
  function() {
    Sys.time() - t0 > timeout
  }
}

start_publisher <- function(channel, dt = 0.02) {
  testthat::skip_on_appveyor()
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("sys")
  skip_if_no_redis()

  Rscript <- file.path(R.home("bin"), "Rscript")
  if (!file.exists(Rscript)) {
    Rscript <- Sys.which("Rscript")
    if (!nzchar(Rscript)) {
      testthat::skip("Did not find Rscript")
    }
  }

  filename <- tempfile("redux_")
  writeLines(c(channel, dt), filename)
  log <- tempfile("redux_")
  Sys.setenv("R_TESTS" = "")

  pid <- sys::exec_background(Rscript, c("./pub_runif.R", filename),
                              std_out = log, std_err = log)

  t <- time_checker(1.0)
  while (!t()) {
    if (file.exists(log)) {
      break
    }
    Sys.sleep(.05)
  }
  if (!is.na(sys::exec_status(pid, FALSE))) {
    stop("Didn't get publisher started")
  }
  list(pid = pid, filename = filename, log = log)
}

`%||%` <- function(a, b) if (is.null(a)) b else a
