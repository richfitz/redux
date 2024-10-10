#include <R.h>
#include <Rinternals.h>
#include <hiredis.h>
#include <stdbool.h>

SEXP redux_redis_connect(SEXP host, SEXP port, SEXP timeout);
SEXP redux_redis_connect_unix(SEXP path, SEXP timeout);

SEXP redux_redis_command(SEXP extPtr, SEXP cmd, SEXP r_as);

SEXP redux_redis_pipeline(SEXP extPtr, SEXP list);

redisContext* redis_get_context(SEXP extPtr, bool closed_error);
