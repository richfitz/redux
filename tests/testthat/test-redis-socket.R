context("socket connection")

test_that("socket connection", {
  skip_if_no_redis()
  skip_on_cran()
  redis_server <- Sys.which("redis-server")
  if (redis_server == "") {
    skip("didn't find redis server")
  }
  logfile <- tempfile("redis_")
  socket <- tempfile("socket_")
  system2(redis_server, c("--port", 0, "--unixsocket", socket),
          wait = FALSE, stdout = logfile, stderr = logfile)
  Sys.sleep(.5)

  if (!file.exists(socket)) {
    ## This does leave a redis server running on a socket!
    skip("Didn't start socket server")
  }
  config <- redis_config()
  ptr_sock <- redis_connect_unix(socket)
  ptr_tcp  <- redis_connect_tcp(config$host, config$port)
  cmp <- redis_status("PONG")
  expect_equal(redis_command(ptr_sock, list("PING")), cmp)
  expect_equal(redis_command(ptr_tcp,  list("PING")), cmp)

  tmp <- hiredis(redis_config(path = socket))
  expect_equal(tmp$PING(), cmp)

  expect_error(redis_command(ptr_sock, "SHUTDOWN"),
               "Failure communicating with the Redis server")
  expect_false(file.exists(socket))
})
