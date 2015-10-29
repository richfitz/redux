# redux

`redux` provides a low-level interface to Redis, allowing execution of arbitrary Redis commands with almost no interface.  While it can be used standalone, it is designed to be used with [`RedisAPI`](https://github.com/ropensci/RedisAPI) which provides a much friendlier interface to the Redis commands.

As well as supporting Redis commands, `redux` supports:

* **pipelineing**: execute more than one command in a single Redis roundtrip, which can greatly increase performance, especially over high-latency connections.
* **socket connections**: can connect to a locally running Redis instance over a unix socket (if Redis is configured to do so) for faster communication.
* **flexible serialisation**: serialise any part of a Redis command, including keys and fields.  Binary serialisation is supported (see `RedisAPI` for a helper functions).
* **subscriptions**: create a simple blocking subscribe client, applying a callback function to every message recieved (see `RedisAPI` for a more friendly interface).
* **error handling**: Every Redis error becomes an  R error.

## Usage

Create a connection:

```r
con <- redis_connection(RedisAPI::redis_config())
```

See `?RedisAPI::redis_config` for details on specifying hosts, ports, servers, etc.  Importantly, _socket connections_ can be used, which can be considerably faster if you are connecting to a local Redis instance and have socket connections enabled.

The connection object provides several functions for interfacing with Redis:

* `reconnect`: Reconnect a disconnected client, using the same options as used to create the connection.
* `command`: Run a redis command.  The format of the argument is given below
* `pipeline`: Run a set of redis commands, as described below, in a single roundtrip with the server.  No logic is possible here, but this can be *much* faster especially over slow connections
* `subscribe`: Support for becoming a blocking subscribe client.  Documentation forthcoming.

### Commands

The simplest command is a character vector, starting with a Redis command, e.g.:

```r
con$command(c("SET", "foo", 1))
```

However, if we wanted to set `foo` to be an R object (e.g. `1:10`), then we need to *serialise* the object.  To do that we use `raw` vectors and the command would become:

```r
con$command(list("SET", "foo", serialize(1:10, NULL)))
```

and to retrieve it:

```r
unserialize(con$command(c("GET", "foo")))
```

Elements of a list command can be:

* Character vectors of any length
* Integer vectors of any length (convered to character)
* Logical vectors of any length (converted to integer then to character)
* A list of raw vectors (note this generates a nested list)

`NULL` values in the list will be skipped over.

## Pipelining

See [the redis documentation](redis.io/topics/pipelining) for background information about pipelining.  In short, evaluating

```r
con$command(c("INCR", "X"))
con$command(c("INCR", "X"))
```

will result in two round trips:

```
Client: INCR X
Server: 1
Client: INCR X
Server: 2
```

These commands can be *pipelined* together into a single request so that the interaction looks like:

```
Client: INCR X
Client: INCR X
Server: 1
Server: 2
```

To do this, the `pipeline` function in the redis object accepts multiple Redis commands as a list:

```r
con$pipeline(list(
  c("INCR", "X"),
  c("INCR", "X")
))
```

(if these arguments are named, then the output will have the same names).  Pipelining plays nicely with transactions:

```r
con$pipeline(list(
  "MULTI",
  c("INCR", "X"),
  c("INCR", "X"),
  "EXEC"
))
```

which will all be evaluated in a single atomic block on the server in a single round trip.

Note the [warnings about pipeline](http://redis.io/topics/pipelining#redis-pipelining) in the official  Redis documentation - sending so many commands (e.g., >10k) memory use on the server can be negatively affected.

## Subscriptions

Subscriptions, really should be done with the `RedisAPI` wrapper, but the brave can use this low-level interface should the need arise.  The `subscribe` function takes arguments:

* `channel`: a vector of one or more channels to listen on
* `pattern`: a logical indicating if the `channel` is a pattern
* `callback`: a function described below
* `envir`: environment to evaluate the function in, by default the parent frame

The callback function must take a single argument; this will be the recieved message with named elements `type` (which will be message), `channel` (the name of the channel) and `value` (the message contents).  If `pattern` was `TRUE`, then an additional element `pattern` will be present (see the Redis docs).  The callback must return `TRUE` or `FALSE`; this indicates if the client should continue quit (i.e., `TRUE` means return control to R, `FALSE` means keep going).

Because the `subscribe` function is blocking and returns nothing, so all data collection needs to happen as a side-effect of the callback function.

Here's an example that will collect values until it has 10 entries:

```
callback <- local({
  i <- 1L
  vals <- numeric(10L)
  function(x) {
    vals[[i]] <<- as.numeric(x$value)
    i <<- i + 1L
    i > 10L
  }
})
con$subscribe("foo", FALSE, callback)
```

This will sit there forever unless something publishes on channel `foo`.  In a second instance you can run:

```
con <- redux::redis_connection(RedisAPI::redis_config())
res <- sapply(1:11, function(i) con$command(c("PUBLISH", "foo", runif(1))))
```

which will return 10 values of 1 and 1 value of 0 (being the number of clients subscribed to the `foo` channel).

Back in the client R instance, the subscriber has detached, and

```
environment(callback)$vals
```

will be a vector of 10 random numbers!

## Installation

```r
devtools::install_github("richfitz/redux")
```

## See also

* [`rredis`](https://cran.r-project.org/web/packages/rredis/index.html), the original R Redis client
* [`RcppRedis`](https://github.com/eddelbuettel/rcppredis), Dirk Eddelbuettel's R Redis client, which greatly influenced the design decisions here
* [`hiredis-rb`](https://github.com/redis/hiredis-rb), the _Ruby_ Redis client that influenced the subscribe and pipeline support here.

## License

GPL-2 © [Rich FitzJohn](https://github.com/richfitz/redux).
