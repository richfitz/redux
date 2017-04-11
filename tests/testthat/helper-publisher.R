## from rrqueue:
time_checker <- function(timeout) {
  t0 <- Sys.time()
  timeout <- as.difftime(timeout, units = "secs")
  function() {
    Sys.time() - t0 > timeout
  }
}

start_publisher <- function(channel, dt = 0.02) {
  skip_if_not_installed("processx")
  filename <- tempfile("redux_")
  writeLines(c(channel, dt), filename)
  log <- tempfile("redux_")
  Sys.setenv("R_TESTS" = "")
  px <- processx::process$new("./pub_runif.R", filename, stderr = log)

  t <- time_checker(1.0)
  while (!t()) {
    if (file.exists(log)) {
      break
    }
    Sys.sleep(.05)
  }
  if (!px$is_alive()) {
    stop("Didn't get publisher started")
  }
  list(px = px, filename = filename)
}
