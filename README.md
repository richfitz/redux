# redux

[![Build Status](https://travis-ci.org/richfitz/redux.png?branch=master)](https://travis-ci.org/richfitz/redux)

`redux` provides a low-level interface to Redis, allowing execution of arbitrary Redis commands with almost no interface.  While it can be used standalone, it is designed to be used with [`RedisAPI`](https://github.com/ropensci/RedisAPI) which provides a much friendlier interface to the Redis commands.

As well as supporting Redis commands, `redux` supports:

* **pipelineing**: execute more than one command in a single Redis roundtrip, which can greatly increase performance, especially over high-latency connections.
* **socket connections**: can connect to a locally running Redis instance over a unix socket (if Redis is configured to do so) for faster communication.
* **flexible serialisation**: serialise any part of a Redis command, including keys and fields.  Binary serialisation is supported (see `RedisAPI` for a helper functions).
* **subscriptions**: create a simple blocking subscribe client, applying a callback function to every message recieved (see `RedisAPI` for a more friendly interface).
* **error handling**: Every Redis error becomes an  R error.

## Usage

Create a hiredis object:

```r
r <- redux::hiredis()
```

The hiredis object is a hiredis object with many (*many* methods), each corresponding to a different Redis command.

```r
r
## <redis_api>
##   Redis commands:
##     APPEND: function
##     AUTH: function
##     BGREWRITEAOF: function
##     BGSAVE: function
##     ...
##     ZSCORE: function
##     ZUNIONSTORE: function
##   Other public methods:
##     clone: function
##     command: function
##     config: function
##     initialize: function
##     pipeline: function
##     reconnect: function
##     subscribe: function
##     type: function
```

All the methods are available from this object; for example to set "foo" to "bar", use:

```
r$SET("foo", "bar")
```

See the package vignette for more information (`vignette("redux")`) or https://richfitz.github.io/redux/vignettes/redux.html

## Installation

```r
devtools::install_github("richfitz/redux")
```

## See also

* [`rredis`](https://cran.r-project.org/web/packages/rredis/index.html), the original R Redis client
* [`RcppRedis`](https://github.com/eddelbuettel/rcppredis), Dirk Eddelbuettel's R Redis client, which greatly influenced the design decisions here
* [`hiredis-rb`](https://github.com/redis/hiredis-rb), the _Ruby_ Redis client that influenced the subscribe and pipeline support here.
* [`rrlite`](https://github.com/ropensci/rrlite), an almost identical interface to [`rlite`](https://github.com/seppo0010/rlite), a serverless-zero configuration database with an identical interface to Redis.

## License

GPL-2 © [Rich FitzJohn](https://github.com/richfitz/redux).
