#!/usr/bin/env Rscript
library(methods)
f <- function(filename) {
  if (!file.exists(filename)) {
    message("No file - exiting")
    return()
  }
  dat <- readLines(filename)
  ch <- dat[[1]]
  dt <- as.numeric(dat[[2]])
  con <- RedisAPI::hiredis()
  message(Sys.getpid())
  flush(stderr())
  while (file.exists(filename)) {
    con$PUBLISH(ch, runif(1))
    Sys.sleep(dt)
  }
}
f(commandArgs(TRUE)[[1]])
