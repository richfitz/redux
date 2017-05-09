# redux

[![Project Status: WIP - Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip)
[![Build Status](https://travis-ci.org/richfitz/redux.png?branch=master)](https://travis-ci.org/richfitz/redux)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/richfitz/redux?branch=master&svg=true)](https://ci.appveyor.com/project/richfitz/redux)
[![codecov.io](https://codecov.io/github/richfitz/redux/coverage.svg?branch=master)](https://codecov.io/github/richfitz/redux?branch=master)

`redux` provides an inteface to Redis.  Two interfaces are provided; a low level interface (allowing execution of arbitrary Redis commands with almost no interface) and a high-level interface with an API that matches all of the several hundred Redis commands.

As well as supporting Redis commands, `redux` supports:

* **pipelineing**: execute more than one command in a single Redis roundtrip, which can greatly increase performance, especially over high-latency connections.
* **socket connections**: can connect to a locally running Redis instance over a unix socket (if Redis is configured to do so) for faster communication.
* **flexible serialisation**: serialise any part of a Redis command, including keys and fields.  Binary serialisation is supported via `object_to_bin` / `bin_to_object`, which are thin wrappers around `serialize` / `unserialize`
* **subscriptions**: create a simple blocking subscribe client, applying a callback function to every message recieved.
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
remotes::install_github("richfitz/redux", upgrade = FALSE)
```

## See also

There is considerable prior work in this space:

* [`rredis`](https://cran.r-project.org/package=rredis), the original R Redis client
* [`RcppRedis`](https://cran.r-project.org/package=RcppRedis), Dirk Eddelbuettel's R Redis client, which greatly influenced the design decisions here
* [`hiredis-rb`](https://github.com/redis/hiredis-rb), the _Ruby_ Redis client that inspired the subscribe and pipeline support here.
* [`rrlite`](https://github.com/ropensci/rrlite), an almost identical interface to [`rlite`](https://github.com/seppo0010/rlite), a serverless-zero configuration database with an identical interface to Redis

## License

GPL-2 © [Rich FitzJohn](https://github.com/richfitz/redux).
