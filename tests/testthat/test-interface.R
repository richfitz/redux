context("interface")

## Multiple args OK:
test_that("MSET / MGET / DEL", {
  r <- test_hiredis_connection()
  expect_equal(r$MSET(letters, LETTERS), redis_status("OK"))
  expect_equal(vapply(letters, r$EXISTS, integer(1), USE.NAMES = FALSE),
               rep(1L, length(letters)))
  expect_equal(r$MGET(letters), as.list(LETTERS))
  expect_equal(r$DEL(letters), length(letters))
  expect_equal(vapply(letters, r$EXISTS, integer(1), USE.NAMES = FALSE),
               rep(0L, length(letters)))
})

## SORT is the most complicated, so lets nail that
test_that("SORT", {
  r <- test_hiredis_connection()
  key <- rand_str()
  i <- sample(20)
  expect_equal(r$RPUSH(key, i), 20)
  on.exit(r$DEL(key))
  res <- r$SORT(key)
  cmp <- as.list(as.character(sort(i)))
  expect_equal(res, cmp)

  ## NOTE: this is a different behaviour to the examples because order
  ## *must* be given as a kw argument here, whereas there it's done
  ## positionally.  Not sure how to implement that, or if it's
  ## worthwhile.
  expect_equal(r$SORT(key, order = "DESC"), rev(cmp))
  expect_equal(r$SORT(key, order = "ASC"), cmp)
  expect_error(r$SORT(key, order = "A"), "order must be one of")

  expect_equal(r$SORT(key, LIMIT = c(0, 10)),
               cmp[1:10])
  expect_equal(r$SORT(key, LIMIT = c(5, 10)),
               cmp[6:15])

  cmp_alpha <- as.list(sort(as.character(i)))
  expect_equal(r$SORT(key, sorting = "ALPHA"), cmp_alpha)
  expect_equal(r$SORT(key, sorting = "ALPHA", order = "DESC"),
               rev(cmp_alpha))

  key2 <- rand_str()
  on.exit(r$DEL(key2), add = TRUE)
  expect_equal(r$SORT(key, STORE = key2), length(i))
  ## TODO: rlite doesn't return a redis_status here, which seems like a bug.
  ##   expect_equal(r$TYPE(key2), redis_status("list")))
  ## A fix would be substituting
  ##   createStringObject -> createStatusObject in hirlite.c:typeCommand()
  expect_equal(as.character(r$TYPE(key2)), "list")
  expect_equal(r$LRANGE(key2, 0, -1), cmp)
})

## SCAN does some cool things; let's try that, too.
test_that("SCAN", {
  r <- test_hiredis_connection()
  skip_if_no_scan(r)

  prefix <- paste0(rand_str(), ":")
  str <- replicate(50, rand_str(prefix = prefix))
  r$MSET(str, str)
  on.exit(r$DEL(str))

  ## The stupid way:
  pat <- paste0(prefix, "*")
  all <- as.character(r$KEYS(pat))
  expect_equal(sort(all), sort(str))

  ## The better way:
  seen <- setNames(integer(length(str)), str)
  cursor <- 0L
  for (i in 1:50) {
    res <- r$SCAN(cursor, pat)
    cursor <- res[[1]]
    i <- as.character(res[[2]])
    seen[i] <- seen[i] + 1L
    if (cursor == "0") {
      break
    }
  }
  expect_equal(cursor, "0")
  expect_true(all(seen > 0))

  ## Try to do it in one big jump:
  res <- r$SCAN(0L, pat, 1000)
  if (res[[1]] == "0") {
    expect_equal(length(res[[2]]), length(str))
    expect_equal(sort(unlist(res[[2]])), sort(str))
  }
})

test_that("serialisation", {
  r <- test_hiredis_connection()

  key <- rand_str()
  on.exit(r$DEL(key))
  expect_equal(r$SET(key, object_to_bin(1:10)), redis_status("OK"))

  expect_is(r$GET(key), "raw")
  expect_equal(bin_to_object(r$GET(key)), 1:10)

  ## And vectorised:
  expect_equal(r$MSET(key, object_to_bin(1:10)), redis_status("OK"))
  expect_equal(bin_to_object(r$GET(key)), 1:10)
  expect_equal(r$MSET(key, list(object_to_bin(1:10))), redis_status("OK"))
  expect_equal(bin_to_object(r$GET(key)), 1:10)

  str <- replicate(10, rand_str(prefix = paste0(rand_str(), ":")))
  on.exit(r$DEL(str), add = TRUE)

  expect_equal(r$MSET(str, 1:10), redis_status("OK"))
  expect_equal(r$MGET(str), as.list(as.character(1:10)))

  expect_error(r$MSET(str, object_to_bin(1:10)),
               "b must be length 10")

  expect_equal(r$MSET(str, lapply(1:10, object_to_bin)), redis_status("OK"))
  tmp <- r$MGET(str)
  expect_true(all(vapply(tmp, is.raw, logical(1))))
  expect_equal(lapply(tmp, bin_to_object), as.list(1:10))
})

test_that("pipeline naming", {
  con <- test_hiredis_connection()
  redis <- redux::redis

  res <- con$pipeline(
    a = redis$SET("a", 1),
    b = redis$GET("a"),
    c = redis$DEL("a"))
  expect_equal(names(res), c("a", "b", "c"))
  expect_equal(res$a, redis_status("OK"))
  expect_equal(res$b, "1")
  expect_equal(res$c, 1)
})
