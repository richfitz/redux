# redux

<!-- badges: start -->
[![Project Status: Active - The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/)
[![R build status](https://github.com/richfitz/redux/workflows/R-CMD-check/badge.svg)](https://github.com/richfitz/redux/actions)
[![codecov.io](https://codecov.io/github/richfitz/redux/coverage.svg?branch=master)](https://codecov.io/github/richfitz/redux?branch=master)
[![](https://www.r-pkg.org/badges/version/redux)](https://cran.r-project.org/package=redux)
<!-- badges: end -->

`redux` provides an interface to Redis.  Two interfaces are provided; a low level interface (allowing execution of arbitrary Redis commands with almost no interface) and a high-level interface with an API that matches all of the several hundred Redis commands.

As well as supporting Redis commands, `redux` supports:

* **pipelineing**: execute more than one command in a single Redis roundtrip, which can greatly increase performance, especially over high-latency connections.
* **socket connections**: can connect to a locally running Redis instance over a unix socket (if Redis is configured to do so) for faster communication.
* **flexible serialisation**: serialise any part of a Redis command, including keys and fields.  Binary serialisation is supported via `object_to_bin` / `bin_to_object`, which are thin wrappers around `serialize` / `unserialize`
* **subscriptions**: create a simple blocking subscribe client, applying a callback function to every message received.
* **error handling**: Every Redis error becomes an  R error.

`redux` also provides a driver for [`storr`](https://cran.r-project.org/package=storr), allowing easy exchange of R objects between computers.

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

## Testing

To use the test suite, please set the environment variables

- `NOT_CRAN=true`
- `REDUX_TEST_USE_REDIS=true`
- `REDUX_TEST_ISOLATED=true`

The first two opt in to using redis _at all_, and the third activates commands that may be destructive or undesirable to use on a production server.

## Installation

Install from CRAN with

```r
install.packages("redux")
```

or install the development version with

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
