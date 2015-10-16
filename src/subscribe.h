#include "connection.h"
SEXP redux_redis_subscribe(SEXP extPtr, SEXP channel, SEXP list, SEXP envir);
SEXP redux_redis_unsubscribe(SEXP extPtr, SEXP channel);
void redux_redis_subscribe_loop(redisContext* context,
                                SEXP callback, SEXP envir);
