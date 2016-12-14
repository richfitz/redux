context("commands - geo")

test_that("GEOADD", {
  skip_if_cmd_unsupported("GEOADD")
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  x <- c(13.361389, 15.087269)
  y <- c(38.115556, 37.502669)
  nms <- c("Palermo", "Catania")
  expect_equal(con$GEOADD(key, x, y, nms), 2)

  expect_equal(con$GEODIST(key, nms[[1]], nms[[2]]), "166274.1516")
  expect_equal(con$GEORADIUS(key, 15, 37, 100, "km"), list(nms[[2]]))
  expect_equal(con$GEORADIUS(key, 15, 37, 200, "km"), as.list(nms))
})

test_that("GEOHASH", {
  skip_if_cmd_unsupported("GEOHASH")
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  x <- c(13.361389, 15.087269)
  y <- c(38.115556, 37.502669)
  nms <- c("Palermo", "Catania")
  con$GEOADD(key, x, y, nms)

  expect_equal(con$GEOHASH(key, nms),
               list("sqc8b49rny0", "sqdtr74hyu0"))
})

test_that("GEOPOS", {
  skip_if_cmd_unsupported("GEOPOS")
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  x <- c(13.361389, 15.087269)
  y <- c(38.115556, 37.502669)
  nms <- c("Palermo", "Catania")
  con$GEOADD(key, x, y, nms)

  con$GEOPOS(key, c(nms, "NonExisting"))
})

test_that("GEODIST", {
  skip_if_cmd_unsupported("GEODIST")
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  x <- c(13.361389, 15.087269)
  y <- c(38.115556, 37.502669)
  nms <- c("Palermo", "Catania")
  con$GEOADD(key, x, y, nms)

  expect_equal(con$GEODIST(key, nms[[1]], nms[[2]]), "166274.1516")
  expect_equal(con$GEODIST(key, nms[[1]], nms[[2]], "km"), "166.2742")
  expect_equal(con$GEODIST(key, nms[[1]], nms[[2]], "mi"), "103.3182")
  expect_null(con$GEODIST(key, "foo", "bar"))
})

test_that("GEORADIUS", {
  skip_if_cmd_unsupported("GEORADIUS")
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  x <- c(13.361389, 15.087269)
  y <- c(38.115556, 37.502669)
  nms <- c("Palermo", "Catania")
  con$GEOADD(key, x, y, nms)

  ## TODO: this is one of the cases I need to tweak; I removed the
  ## code that tested for them though.
  dat <- con$GEORADIUS(key, 15, 37, 200, "km", withdist = "WITHDIST")
  expect_equal(dat, list(list("Palermo", "190.4424"),
                         list("Catania", "56.4413")))
  dat <- con$GEORADIUS(key, 15, 37, 200, "km", withcoord = "WITHCOORD")
  cmp <-
    list(list("Palermo", list("13.36138933897018433", "38.11555639549629859")),
         list("Catania", list("15.08726745843887329", "37.50266842333162032")))
  expect_equal(dat, cmp)

  dat <- con$GEORADIUS(key, 15, 37, 200, "km",
                       withcoord = "WITHCOORD", withdist = "WITHDIST")
  cmp <- list(
    list("Palermo", "190.4424",
         list("13.36138933897018433", "38.11555639549629859")),
    list("Catania", "56.4413",
         list("15.08726745843887329", "37.50266842333162032")))
  expect_equal(dat, cmp)
})

test_that("GEORADIUSBYMEMBER", {
  skip_if_cmd_unsupported("GEORADIUSBYMEMBER")
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$GEOADD(key, 13.583333, 37.316667, "Agrigento")
  x <- c(13.361389, 15.087269)
  y <- c(38.115556, 37.502669)
  nms <- c("Palermo", "Catania")
  con$GEOADD(key, x, y, nms)

  expect_equal(con$GEORADIUSBYMEMBER(key, "Agrigento", 100, "km"),
               list("Agrigento", "Palermo"))
})
