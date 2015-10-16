# redux

> redux

redux

## Usage

Create a connection:

```r
con <- redis()
```

or specify options:

```r
con <- redis(host="myserver", port=9999, db=2)
con <- redis(url="redis://myserver:9999/2")
```

or connect to a socket

```r
con <- redis(path="/tmp/redis.sock")
```

## Installation

```r
devtools::install_github("richfitz/redux")
```

## License

GPL-2 © [Rich FitzJohn](https://github.com/richfitz/redux).
