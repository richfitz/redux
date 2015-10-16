#include <R.h>
#include <Rinternals.h>
#include <hiredis.h>

#define CLOSED_PASS 0
#define CLOSED_WARN 1
#define CLOSED_ERROR 2

SEXP redux_redis_connect(SEXP host, SEXP port);
SEXP redux_redis_connect_unix(SEXP path);

SEXP redux_redis_command(SEXP extPtr, SEXP cmd);

SEXP redux_redis_pipeline(SEXP extPtr, SEXP list);

redisContext* redis_get_context(SEXP extPtr, int closed_action);
