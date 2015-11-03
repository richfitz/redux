#include "connection.h"
SEXP redux_redis_subscribe(SEXP extPtr, SEXP channel, SEXP pattern,
                           SEXP list, SEXP envir);
SEXP redux_redis_unsubscribe(SEXP extPtr, SEXP channel, SEXP pattern);
void redux_redis_subscribe_loop(redisContext* context,
                                int pattern, SEXP callback, SEXP envir);
