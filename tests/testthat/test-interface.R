context("interface")

## Multiple args OK:
test_that("MSET / MGET / DEL", {
  skip_if_no_redis()
  r <- hiredis()
  expect_that(r$MSET(letters, LETTERS), is_OK())
  expect_that(vapply(letters, r$EXISTS, integer(1), USE.NAMES=FALSE),
              equals(rep(1L, length(letters))))
  expect_that(r$MGET(letters), equals(as.list(LETTERS)))
  expect_that(r$DEL(letters), equals(length(letters)))
  expect_that(vapply(letters, r$EXISTS, integer(1), USE.NAMES=FALSE),
              equals(rep(0L, length(letters))))
})

## SORT is the most complicated, so lets nail that
test_that("SORT", {
  skip_if_no_redis()
  key <- rand_str()
  i <- sample(20)
  r <- hiredis()
  expect_that(r$RPUSH(key, i), equals(20))
  on.exit(r$DEL(key))
  res <- r$SORT(key)
  cmp <- as.list(as.character(sort(i)))
  expect_that(res, equals(cmp))

  ## NOTE: this is a different behaviour to the examples because order
  ## *must* be given as a kw argument here, whereas there it's done
  ## positionally.  Not sure how to implement that, or if it's
  ## worthwhile.
  expect_that(r$SORT(key, order="DESC"), equals(rev(cmp)))
  expect_that(r$SORT(key, order="ASC"), equals(cmp))
  expect_that(r$SORT(key, order="A"),
              throws_error("order must be one of"))

  expect_that(r$SORT(key, LIMIT=c(0, 10)),
              equals(cmp[1:10]))
  expect_that(r$SORT(key, LIMIT=c(5, 10)),
              equals(cmp[6:15]))

  cmp_alpha <- as.list(sort(as.character(i)))
  expect_that(r$SORT(key, sorting="ALPHA"), equals(cmp_alpha))
  expect_that(r$SORT(key, sorting="ALPHA", order="DESC"),
              equals(rev(cmp_alpha)))

  key2 <- rand_str()
  on.exit(r$DEL(key2))
  expect_that(r$SORT(key, STORE=key2), equals(length(i)))
  ## TODO: rlite doesn't return a redis_status here, which seems like a bug.
  ##   expect_that(r$TYPE(key2), equals(redis_status("list")))
  ## A fix would be substituting
  ##   createStringObject -> createStatusObject in hirlite.c:typeCommand()
  expect_that(as.character(r$TYPE(key2)), equals("list"))
  expect_that(r$LRANGE(key2, 0, -1), equals(cmp))
})

## SCAN does some cool things; let's try that, too.
test_that("SCAN", {
  skip_if_no_redis()
  r <- hiredis()
  skip_if_no_scan(r)

  prefix <- paste0(rand_str(), ":")
  str <- replicate(50, rand_str(prefix=prefix))
  r$MSET(str, str)
  on.exit(r$DEL(str))

  ## The stupid way:
  pat <- paste0(prefix, "*")
  all <- as.character(r$KEYS(pat))
  expect_that(sort(all), equals(sort(str)))

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
  expect_that(cursor, equals("0"))
  expect_that(all(seen > 0), is_true())

  ## Try to do it in one big jump:
  res <- r$SCAN(0L, pat, 1000)
  if (res[[1]] == "0") {
    expect_that(length(res[[2]]), equals(length(str)))
    expect_that(sort(unlist(res[[2]])), equals(sort(str)))
  }
})

test_that("serialisation", {
  skip_if_no_redis()
  object_to_bin <- RedisAPI::object_to_bin
  bin_to_object <- RedisAPI::bin_to_object

  r <- hiredis()

  key <- rand_str()
  on.exit(r$DEL(key))
  expect_that(r$SET(key, object_to_bin(1:10)), is_OK())

  expect_that(r$GET(key), is_a("raw"))
  expect_that(bin_to_object(r$GET(key)), equals(1:10))

  ## And vectorised:
  expect_that(r$MSET(key, object_to_bin(1:10)), is_OK())
  expect_that(bin_to_object(r$GET(key)), equals(1:10))
  expect_that(r$MSET(key, list(object_to_bin(1:10))), is_OK())
  expect_that(bin_to_object(r$GET(key)), equals(1:10))

  str <- replicate(10, rand_str(prefix=paste0(rand_str(), ":")))
  on.exit(r$DEL(str), add=TRUE)

  expect_that(r$MSET(str, 1:10), is_OK())
  expect_that(r$MGET(str), equals(as.list(as.character(1:10))))

  expect_that(r$MSET(str, object_to_bin(1:10)),
              throws_error("b must be length 10"))

  expect_that(r$MSET(str, lapply(1:10, object_to_bin)), is_OK())
  tmp <- r$MGET(str)
  expect_that(all(vapply(tmp, is.raw, logical(1))), is_true())
  expect_that(lapply(tmp, bin_to_object), equals(as.list(1:10)))
})
