#include "connection.h"
SEXP redux_redis_subscribe(SEXP extPtr, SEXP channel, SEXP list, SEXP envir,
                           SEXP pattern);
SEXP redux_redis_unsubscribe(SEXP extPtr, SEXP channel, SEXP pattern);
void redux_redis_subscribe_loop(redisContext* context,
                                SEXP callback, SEXP envir, int pattern);
