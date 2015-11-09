context("socket connection")

test_that("socket connection", {
  redis_server <- Sys.which("redis-server")
  if (redis_server == "") {
    skip("didn't find redis server")
  }
  logfile <- tempfile("redis_")
  socket <- tempfile("socket_")
  system2(redis_server, c("--port", 0, "--unixsocket", socket),
          wait=FALSE, stdout=logfile, stderr=logfile)
  Sys.sleep(.5)

  if (!file.exists(socket)) {
    ## This does leave a redis server running on a socket!
    skip("Didn't start socket server")
  }
  ptr_sock <- redis_connect_unix(socket)
  ptr_tcp  <- redis_connect_tcp("127.0.0.1", 6379L)
  cmp <- redis_status("PONG")
  expect_that(redis_command(ptr_sock, list("PING")), equals(cmp))
  expect_that(redis_command(ptr_tcp,  list("PING")), equals(cmp))

  expect_that(redis_command(ptr_sock, "SHUTDOWN"),
              throws_error("Failure communicating with the Redis server"))
  expect_that(file.exists(socket), is_false())
})
