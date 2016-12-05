##' Serialise/deserialise an R object into a string.  This is a very
##' thin wrapper around the existing R functions
##' \code{\link{serialize}} and \code{\link{rawToChar}}.  This is
##' useful to encode arbitrary R objects as string to then save in
##' Redis (which expects a string).
##' @title Convert R objects to/from strings
##' @param obj An R object to convert into a string
##' @export
##' @examples
##' s <- object_to_string(1:10)
##' s
##' string_to_object(s)
##' identical(string_to_object(s), 1:10)
object_to_string <- function(obj) {
  rawToChar(serialize(obj, NULL, NA))
}
##' @param str A string to convert into an R object
##' @export
##' @rdname object_to_string
string_to_object <- function(str) {
  unserialize(charToRaw(str))
}

##' @export
##' @rdname object_to_string
##'
##' @param xdr Use the big-endian representation?  Unlike,
##'   \code{\link{serialize}} this is disabled here by default as it
##'   is a bit faster (~ 20%, saving about 1 microsecond of a 5
##'   microsecond roundtrip for a serialization of 100 doubles)
object_to_bin <- function(obj, xdr = FALSE) {
  serialize(obj, NULL, xdr = xdr)
}
##' @export
##' @rdname object_to_string
##' @param bin A binary vector to convert back to an R object
bin_to_object <- function(bin) {
  unserialize(bin)
}
