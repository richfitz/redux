#!/usr/bin/env Rscript
args <- commandArgs(TRUE)
if (length(args) != 6L) {
  stop("Expected 6 arguments")
}
host <- args[[1L]]
port <- as.integer(args[[2L]])
key <- args[[3L]]
period <- as.integer(args[[4L]])
expire <- as.integer(args[[5L]])
sleep <- as.integer(args[[6L]])
message("host: ", host)
message("port: ", port)
message("key: ", key)
message("period: ", period)
message("expire: ", expire)
config <- list(host = host, port = port)
key <- redux::heartbeat(key, period, expire, config = config)
Sys.sleep(sleep)
