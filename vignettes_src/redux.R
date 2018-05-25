## ---
## title: "Using Redis with redux"
## author: "Rich FitzJohn"
## date: "`r Sys.Date()`"
## output: rmarkdown::html_vignette
## vignette: >
##   %\VignetteIndexEntry{Using Redis with redux}
##   %\VignetteEngine{knitr::rmarkdown}
##   \usepackage[utf8]{inputenc}
## ---

##+ echo = FALSE,results = "hide"
library(methods)
knitr::opts_chunk$set(error = FALSE)
redux::hiredis()$DEL(c("mykey", "mylist", "mylist2", "rlist"))
set.seed(1)

## `redux` provides a full interface to the Redis API; it provides a
## hiredis driver wrapped in R and uses this to expose all
## `r length(names(redux::redis))` Redis commands as a set of
## user-friendly R functions that do basic error checking.

## It is possible to build user-friendly applications on top of this,
## for example [`storr`](https://github.com/richfitz/storr) which
## provides a content-addressable object store, and
## [`rrqueue`](https://github.com/traitecoevo/rrqueue) /
## [`rrq`](https://github.com/richfitz/rrq) which implement a scalable
## queuing system.

## The main entry point for creating a `redis_api` object is the
## `hiredis` function:
r <- redux::hiredis()

## By default, it will connect to a database running on the local
## machine (`127.0.0.1`) and port 6379.  To connect to a different
## host, or to specify a password, initial database, or to use a
## socket connection, use the command \code{redis_config}.

## The `redis_api` object is an [`R6`](https://github.com/wch/R6)
## class with _many_ methods, each corresponding to a different Redis
## command.
##+ eval = FALSE
r
##+ echo = FALSE
res <- capture.output(print(r))
res <- c(res[1:6], "    ...",
         res[(max(grep("\\s+[A-Z]", res)) - 2):length(res)])
writeLines(res)

## For example, `SET` and `GET`:
r$SET("mykey", "mydata") # set the key "mykey" to the value "mydata"
r$GET("mykey")

## # Serialisation

## The value for most arguments must be a string or will be coerced
## into one; clearly this is not going to be suitable for most R
## objects.  The solution is to *serialise* the R object.  `redux` can
## accept objects serialised to strings or to byte streams, and the
## functions the `object_to_bin` and `object_to_string` functions can
## help here, serialising the objects to binary and string
## representations.  (Alternatively you can do this yourself using
## `serialize`.)
obj <- redux::object_to_bin(1:10)
obj

## or
str <- redux::object_to_string(1:10)
str

## The binary serialisation is faster, smaller, and preserves all the
## bits of floating point numbers.  The string version might be
## preferable where having only strings in the database is wanted.
## The binary serialisation is compatible with the same approach used
## in `RcppRedis`, though it is never done automatically.

## These values can be deserialised:
redux::bin_to_object(obj)
redux::string_to_object(str)

## So:
r$SET("mylist", redux::object_to_bin(1:10))
r$GET("mylist")
redux::bin_to_object(r$GET("mylist"))

## Using string serialisation is similar:
r$SET("mylist", redux::object_to_string(1:10))
r$GET("mylist")
redux::string_to_object(r$GET("mylist"))

## This gives you all the power of Redis, but you will have to
## manually serialise/deserialise all complicated R objects (i.e.,
## everything other than logicals, numbers or strings).  Similarly,
## you are responsible for type coercion/deserialisation when
## retrieving data at the other end.

## Note that you are not restricted to using serialised R objects as
## values; you can use them as keys; this is perfectly valid:
r$SET(redux::object_to_bin(1:10), "mydata")
r$GET(redux::object_to_bin(1:10))
##+ echo = FALSE, results = "hide"
r$DEL(redux::object_to_bin(1:10))

## Beyond `GET` / `SET` / `DEL`, Redis offers potentially better ways
## of holding things like lists using its native data types.  For
## example;

r$RPUSH("mylist2", 1:10)

## (the returned value `10` indicates that the list "mylist2" is 10
## elements long).  There are lots of commands for operating on lists.
## For example, you can do things like;

## * get an element by its index (note that this uses C-style base-0
## indexing for consistency with the `Redis` documentation rather than
## R's semantics)
r$LINDEX("mylist2", 1)

## * set an element by its index
r$LSET("mylist2", 1, "carrot")

## * get all of a list:
r$LRANGE("mylist2", 0, -1)

## * or part of it:
r$LRANGE("mylist2", 0, 2)

## * pop elements off the front or back
r$LLEN("mylist2")
r$LPOP("mylist2")
r$RPOP("mylist2")
r$LLEN("mylist2")

## Of course, each element of the list can be an R object if you run
## it through `object_to_string`:
r$LPUSH("mylist2", redux::object_to_string(1:10))

## but you'll be responsible for converting that back (and detecting
## / knowing that this needs doing)
dat <- r$LRANGE("mylist2", 0, 2)
dat
dat[[1]] <- redux::string_to_object(dat[[1]])
dat

## As with all functions in the `redis_api` object, all functions and
## their arguments are described in the Redis documentation.

## # Pipelining

## Every command set to Redis costs a round trip; even over the
## loopback interface this can be expensive if done a very large
## number of times.  Redis offers two ways of minimising this problem;
## pipelining and lua scripting.  redux supports both.

## To pipeline, use the `pipeline` method of the `hiredis` object:
redis <- redux::redis
r$pipeline(
  redis$PING(),
  redis$PING())

## Here, `redis` is a special object within the package that
## implements all the Redis commands but only formats them for use
## rather than sends them.  The `pipeline` method collects these all
## up and sends them to the server in a single batch, with the result
## returned as a list.

## If arguments are named, then the return value is named:
r$pipeline(
  a = redis$INCR("x"),
  b = redis$INCR("x"),
  c = redis$DEL("x"))

## here a variable "x" was incremented twice and then deleted.

## If you use pipelining you should read the [Redis page on
## it](http://redis.io/topics/pipelining) because there are a few
## restrictions and cautions.

## Generating very large numbers (or variable numbers) of commands
## with the above interface will be difficult because `pipeline` uses
## the dots argument.  Instead, you can pass a list of commands to the
## `.commands` argument of `pipeline`:
cmds <- lapply(seq_len(4), function(.) redis$PING())
r$pipeline(.commands = cmds)

## # Subscriptions

## On top of the key/value store aspect of Redis, it also offers a
## publisher/subscriber model.  Publishing with `redux` is
## straightforward; use the `PUBLISH` method:
r$PUBLISH("mychannel", "hello")

## The return value here is the number of subscribers to that channel;
## in our case zero!

## The `SUBSCRIBE` method should not be used as the client cannot deal
## with messages directly (it is disabled in the interface to prevent
## this).

## Instead, use the `subscribe` (lower case) method.  This takes arguments:
##
## * `channel`: name or pattern of the channel/s to subscribe to
##   (scalar or vector).
##
## * `transform`: A function that takes each message and processes it.
##   Messages are R lists with elements: `type`, `pattern` (if a
##   pattern was used), `channel` and `value` (see the Redis docs).
##   Your transform function can turn this into anything it wants, and
##   may have side effects such as printing to the screen, writing to
##   a file, etc.
##
## * `terminate`: A termination criterion.  given a *transformed*
##   message (i.e., the result of `transform(x)`) return `TRUE` if
##   we're processing messages.  Optional, but if not used set `n` to
##   a finite number.
##
## * collect: logical indicating if *transformed* messages should be
##   collected and returned on exit.
##
## * n: maximum number of messages to collect; once `n` messages have
##   been collected we will terminate regardless of `terminate`.
##
## * pattern: logical indicating if `channel` should be interpreted as
##  a pattern.
##
## * envir: environment in which to evaluate `transform` and `terminate`.

## That all sounds a lot more complicated it really is.  To collect
## all messages on the `"mychannel"` channel, stopping after 100
## messages or a message reading exactly "goodbye" you would write:
##+ eval = FALSE
res <- r$subscribe("mychannel",
                   transform = function(x) x$value,
                   terminate = function(x) identical(x, "goodbye"),
                   n = 100)

## *NOTE*: you need to be careful here - `hiredis` internally uses a
## blocking read which cannot be interrupted with Ctrl-C once started
## unless a message is received on the channels being listened to!

## To test this out, we need a second process that will publish to the
## channel (or we'll wait forever).  This function will publish the
## first 20 values out of the Nile data set.
##+ echo = FALSE
path_to_publisher <- tempfile()
writeLines('r <- redux::hiredis()
for (i in Nile[1:20]) {
  Sys.sleep(.05)
  r$PUBLISH("mychannel", i)
}
r$PUBLISH("mychannel", "goodbye")', path_to_publisher)

##+ echo = FALSE, results = "asis"
writeLines(c("```r", readLines(path_to_publisher), "```"))

## This file is at `path_to_publisher` (in R's temporary directory)
## and can be run with:
system2(file.path(R.home("bin"), "Rscript"), path_to_publisher,
        wait = FALSE, stdout = FALSE, stderr = FALSE)

## to start the publisher.

## Let's add a little debugging information to the transform function,
## and set the subscriber off:
transform <- function(x) {
  message(format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
          ": got message: ",
          x$value)
  x$value
}
##+ subscription
res <- r$subscribe("mychannel",
                   transform = transform,
                   terminate = function(x) identical(x, "goodbye"),
                   n = 100)

##+ echo = FALSE, results = "hide"
file.remove(path_to_publisher)

## The timestamps in the printed output show when the message was
## received (with fractional seconds so that this is more obvious
## since this only takes ~1s to complete).

## The `res` object contains all the values, including the "goodbye"
## that was our end-of-stream message:
unlist(res)

## # Potential applications

## Because `redux` exposes all of Redis, you can roll your own data
## structures.

## First, a generator object that sets up a new list at `key` within
## the database `r`.
rlist <- function(..., key = "rlist", r = redux::hiredis()) {
  dat <- vapply(c(...), redux::object_to_string, character(1))
  r$RPUSH(key, dat)
  ret <- list(r = r, key = key)
  class(ret) <- "rlist"
  ret
}

## Then some S3 methods that work with this object.  I've only
## implemented `length` and `[[`, but `[` would be useful here too as
## would `print`.
length.rlist <- function(x) {
  x$r$LLEN(x$key)
}

`[[.rlist` <- function(x, i, ...) {
  redux::string_to_object(x$r$LINDEX(x$key, i - 1L))
}

`[[<-.rlist` <- function(x, i, value, ...) {
  x$r$LSET(x$key, i - 1L, redux::object_to_string(value))
  x
}

## Then we have this weird object we can add things to.
obj <- rlist(1:10)
length(obj) # 10
obj[[3]]
obj[[3]] <- "an element"
obj[[3]]

## The object has reference semantics so that assignment does *not* make a copy:
obj2 <- obj
obj2[[2]] <- obj2[[2]] * 2
obj[[2]] == obj2[[2]]

## For a better version of this, see
## [storr](https://github.com/richfitz/storr) which does similar things to implement "[indexable serialisation](http://htmlpreview.github.io/?https://raw.githubusercontent.com/richfitz/storr/master/inst/doc/storr.html#lists-and-indexable-serialisation)"

## # Scripts

## Redis allows storing and evaluating Lua scripts on the redis server.
## At this point it's all getting a bit meta (using R to tell Redis to
## call another dynamic language that drives Redis) but this can be
## very useful - especially in avoiding race conditions (because a
## script is atomic) and avoiding roundtrips.

## Describing how to write Lua scripts is out of scope for this
## document but is a bit fiddly.  Here is a trivial one that returns
## the value of a key:
r$SET("key", "a")
res <- r$EVAL("return redis.call('get', 'key')", 1L, "key", NULL)

## This can also be run by pushing the script into Redis and referring
## to it by SHA:
sha <- r$SCRIPT_LOAD("return redis.call('get', 'key')")
r$SCRIPT_EXISTS(sha)

## and calling it like so:
r$EVALSHA(sha, 1, "key", NULL)

## A more interesting example, setting, incrementing and getting a key
## (this is all do-able with redis commands)
lua <- '
  local keyname = KEYS[1]
  local value = ARGV[1]
  redis.call("SET", keyname, value)
  redis.call("INCR", keyname)
  return redis.call("GET", keyname)'

## With the `redis_scripts` wrapper you can give friendly names to a script:
obj <- redux::redis_scripts(r, set_and_incr = lua)

## And then call them by name:
res <- obj("set_and_incr", "foo", "10")
res

## # Getting help

## Because the interface `redux` uses is simply a wrapper around the
## Redis API, the main source of documentation is the Redis help
## itself at http://redis.io
