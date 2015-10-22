# redux

This is a new low-level Redis client.  This is not intended for general use, but should instead be used with [`RedisAPI`](https://github.com/ropensci/RedisAPI).

## Usage

Create a connection:

```r
con <- redis_connection(RedisAPI::redis_config())
```

See `?RedisAPI::redis_config` for details on the changing hosts, ports, servers, etc.  Importantly, _socket connections_ can be used, which can be considerably faster if you are connecting to a local Redis instance and have socket connections enabled.

The connection object provides several functions for interfacing with Redis:

* `reconnect`: Reconnect a disconnected client, using the same options as used to create the connection.
* `command`: Run a redis command.  The format of the argument is given below
* `pipeline`: Run a set of redis commands, as described below, in a single roundtrip with the server.  No logic is possible here, but this can be *much* faster especially over slow connections
* `subscribe`: Support for becoming a blocking subscribe client.  Documentation forthcoming.

### Commands

The simplest command is a character vector, starting with a Redis command, e.g.:

```r
c("SET", "foo", 1)
```

However, if we wanted to set `foo` to be an R object (e.g. `1:10`), then we need to *serialise* the object.  To do that we use `raw` vectors and the command would become:

```r
list("SET", "foo", serialize(1:10, NULL))
```

Elements of a list command can be:

* Character vectors of any length
* Integer vectors of any length (convered to character)
* Logical vectors of any length (converted to integer then to character)
* A list of raw vectors (note this generates a nested list)

`NULL` values in the list will be skipped over.

## Installation

```r
devtools::install_github("richfitz/redux")
```

## License

GPL-2 © [Rich FitzJohn](https://github.com/richfitz/redux).
