#include <R.h>
#include <Rinternals.h>
#include <hiredis.h>
#include <hiredis_ssl.h>
#include <stdbool.h>

SEXP redux_redis_connect(SEXP host, SEXP port);
SEXP redux_redis_connect_ssl(SEXP host, SEXP port, 
                             SEXP CApath, SEXP certPath, SEXP keyPath);
SEXP redux_redis_connect_unix(SEXP path);

SEXP redux_redis_command(SEXP extPtr, SEXP cmd);

SEXP redux_redis_pipeline(SEXP extPtr, SEXP list);

redisContext* redis_get_context(SEXP extPtr, bool closed_error);
