context("commands - cluster")

test_that("CLUSTER ADDSLOTS", {
  expect_equal(redis_cmds$CLUSTER_ADDSLOTS(1:3),
               list("CLUSTER", "ADDSLOTS", 1:3))
})

test_that("CLUSTER COUNT-FAILURE-REPORTS", {
  expect_equal(redis_cmds$CLUSTER_COUNT_FAILURE_REPORTS("id"),
               list("CLUSTER", "COUNT-FAILURE-REPORTS", "id"))
})

test_that("CLUSTER COUNTKEYSINSLOT", {
  expect_equal(redis_cmds$CLUSTER_COUNTKEYSINSLOT(7000),
               list("CLUSTER", "COUNTKEYSINSLOT", 7000))
})

test_that("CLUSTER DELSLOTS", {
  expect_equal(redis_cmds$CLUSTER_DELSLOTS(c(5000, 5001)),
               list("CLUSTER", "DELSLOTS", c(5000, 5001)))
})

test_that("CLUSTER FAILOVER", {
  expect_equal(redis_cmds$CLUSTER_FAILOVER(),
               list("CLUSTER", "FAILOVER", NULL))
  expect_equal(redis_cmds$CLUSTER_FAILOVER("FORCE"),
               list("CLUSTER", "FAILOVER", "FORCE"))
  expect_equal(redis_cmds$CLUSTER_FAILOVER("TAKEOVER"),
               list("CLUSTER", "FAILOVER", "TAKEOVER"))
})

test_that("CLUSTER FORGET", {
  expect_equal(redis_cmds$CLUSTER_FORGET("id"),
               list("CLUSTER", "FORGET", "id"))
})

test_that("CLUSTER GETKEYSINSLOT", {
  expect_equal(redis_cmds$CLUSTER_GETKEYSINSLOT(7000, 3),
               list("CLUSTER", "GETKEYSINSLOT", 7000, 3))
})

test_that("CLUSTER INFO", {
  expect_equal(redis_cmds$CLUSTER_INFO(),
               list("CLUSTER", "INFO"))
})

test_that("CLUSTER KEYSLOT", {
  expect_equal(redis_cmds$CLUSTER_KEYSLOT("somekey"),
               list("CLUSTER", "KEYSLOT", "somekey"))
})

test_that("CLUSTER MEET", {
  expect_equal(redis_cmds$CLUSTER_MEET("B-ip", "B-port"),
               list("CLUSTER", "MEET", "B-ip", "B-port"))
})

test_that("CLUSTER NODES", {
  expect_equal(redis_cmds$CLUSTER_NODES(),
               list("CLUSTER", "NODES"))
})

test_that("CLUSTER REPLICATE", {
  expect_equal(redis_cmds$CLUSTER_REPLICATE("id"),
               list("CLUSTER", "REPLICATE", "id"))
})

test_that("CLUSTER RESET", {
  expect_equal(redis_cmds$CLUSTER_RESET(),
               list("CLUSTER", "RESET", NULL))
  expect_equal(redis_cmds$CLUSTER_RESET("HARD"),
               list("CLUSTER", "RESET", "HARD"))
  expect_equal(redis_cmds$CLUSTER_RESET("SOFT"),
               list("CLUSTER", "RESET", "SOFT"))
})

test_that("CLUSTER SAVECONFIG", {
  expect_equal(redis_cmds$CLUSTER_SAVECONFIG(),
               list("CLUSTER", "SAVECONFIG"))
})

test_that("CLUSTER SET-CONFIG-EPOCH", {
  expect_equal(redis_cmds$CLUSTER_SET_CONFIG_EPOCH("config-epoch"),
               list("CLUSTER", "SET-CONFIG-EPOCH", "config-epoch"))
})

test_that("CLUSTER SETSLOT", {
  expect_equal(redis_cmds$CLUSTER_SETSLOT(7000, "IMPORTING"),
               list("CLUSTER", "SETSLOT", 7000, "IMPORTING", NULL))
})

test_that("CLUSTER SLAVES", {
  expect_equal(redis_cmds$CLUSTER_SLAVES("id"),
               list("CLUSTER", "SLAVES", "id"))
})

test_that("CLUSTER SLOTS", {
  expect_equal(redis_cmds$CLUSTER_SLOTS(),
               list("CLUSTER", "SLOTS"))
})

test_that("READONLY", {
  expect_equal(redis_cmds$READONLY(),
               list("READONLY"))
})

test_that("READWRITE", {
  expect_equal(redis_cmds$READWRITE(),
               list("READWRITE"))
})
