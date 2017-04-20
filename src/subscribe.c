#include "subscribe.h"
#include "conversions.h"

SEXP redux_redis_subscribe(SEXP extPtr, SEXP channel, SEXP pattern,
                           SEXP callback, SEXP envir) {
  const int p = INTEGER(pattern)[0];
  SEXP cmd = PROTECT(allocVector(VECSXP, 2));
  SET_VECTOR_ELT(cmd, 0, mkString(p ? "PSUBSCRIBE" : "SUBSCRIBE"));
  SET_VECTOR_ELT(cmd, 1, channel);
  cmd = PROTECT(redis_check_command(cmd));
  SEXP ret = PROTECT(redux_redis_command(extPtr, cmd));

  redux_redis_subscribe_loop(redis_get_context(extPtr, true),
                             p, callback, envir);

  UNPROTECT(3);
  return ret;
}

void redux_redis_subscribe_loop(redisContext* context, int pattern,
                                SEXP callback, SEXP envir) {
  SEXP call = PROTECT(lang2(callback, R_NilValue));
  redisReply *reply = NULL;
  int keep_going = 1;
  // Nasty:
  SEXP nms = PROTECT(allocVector(STRSXP, pattern ? 4 : 3));
  int i = 0;
  SET_STRING_ELT(nms, i++, mkChar("type"));
  if (pattern) {
    SET_STRING_ELT(nms, i++, mkChar("pattern"));
  }
  SET_STRING_ELT(nms, i++, mkChar("channel"));
  SET_STRING_ELT(nms, i++, mkChar("value"));

  // And we're off.  Adding a timeout here seems sensible to me as
  // that would allow for _some_ sort of interrupt checking, but as it
  // is, this seems extremely difficult to do without risking killing
  // the client.
  while (keep_going) {
    R_CheckUserInterrupt();
    redisGetReply(context, (void*)&reply);
    SEXP x = PROTECT(redis_reply_to_sexp(reply, false));
    setAttrib(x, R_NamesSymbol, nms);
    SETCADR(call, x);
    freeReplyObject(reply);
    SEXP val = PROTECT(eval(call, envir));
    if (TYPEOF(val) == LGLSXP && LENGTH(val) == 1 && INTEGER(val)[0] == 1) {
      keep_going = 0;
    }
    UNPROTECT(2); // x, val
  }
  UNPROTECT(2); // nms, call
}

SEXP redux_redis_unsubscribe(SEXP extPtr, SEXP channel, SEXP pattern) {
  redisContext *context = redis_get_context(extPtr, true);
  // Issue the unsubscribe command:
  const int p = INTEGER(pattern)[0];
  SEXP cmd = PROTECT(allocVector(VECSXP, 2));
  SET_VECTOR_ELT(cmd, 0, mkString(p ? "PUNSUBSCRIBE" : "UNSUBSCRIBE"));
  SET_VECTOR_ELT(cmd, 1, channel);
  cmd = PROTECT(redis_check_command(cmd));
  // Arrange the command:
  const char **argv = NULL;
  size_t *argvlen = NULL;
  const size_t argc = sexp_to_redis(cmd, &argv, &argvlen);
  // Issue the unsubscribe request:
  redisReply *reply = redisCommandArgv(context, argc, argv, argvlen);
  // Then loop until the reply looks correct.
  int n_discarded = 0;
  while (1) {
    if (reply == NULL) {
      // Here, we probably should consider destroying the client as
      // there is no API way of ensuring that the responses are dealt
      // with.
      //
      // This needs testing with toxiproxy.
      error("Redis connection error: client likely in awkward spot"); // # nocov
    }
    // This is possibly over-cautious, but it doesn't really hurt.
    if (reply->type == REDIS_REPLY_ARRAY && reply->elements == 3) {
      redisReply *reply0 = reply->element[0];
      if (reply0->type == REDIS_REPLY_STRING &&
          strcmp(reply0->str, p ? "punsubscribe" : "unsubscribe") == 0) {
        break;
      }
    }
    freeReplyObject(reply);
    reply = NULL;
    n_discarded++;
    redisGetReply(context, (void*)&reply);
  }
  SEXP ret = PROTECT(redis_reply_to_sexp(reply, true));
  freeReplyObject(reply);
  if (n_discarded > 0) {
    setAttrib(ret, mkString("n_discarded"), ScalarInteger(n_discarded));
  }
  UNPROTECT(3);
  return ret;
}
