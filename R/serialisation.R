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
  rawToChar(serialize(obj, NULL, TRUE))
}
##' @param str A string to convert into an R object
##' @export
##' @rdname object_to_string
string_to_object <- function(str) {
  unserialize(charToRaw(str))
}

##' @importFrom RApiSerialize serializeToRaw
C_serializeToRaw <- NULL
C_unserializeFromRaw <- NULL
##' @export
##' @rdname object_to_string
object_to_bin <- function(obj) {
  .Call(C_serializeToRaw, obj)
}
##' @export
##' @rdname object_to_string
##' @param bin A binary vector to convert back to an R object
bin_to_object <- function(bin) {
  .Call(C_unserializeFromRaw, bin)
}

## Vectorised versions:
lobject_to_string <- function(obj) {
  vcapply(obj, object_to_string)
}
string_to_lobject <- function(obj) {
  lapply(str, string_to_object)
}
lobject_to_bin <- function(obj) {
  lapply(obj, function(x) .Call(C_serializeToRaw, x))
}
bin_to_lobject <- function(bin) {
  lapply(bin, bin_to_object)
}
