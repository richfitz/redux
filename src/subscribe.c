#include "subscribe.h"
#include "conversions.h"

SEXP redux_redis_subscribe(SEXP extPtr, SEXP channel,
                           SEXP callback, SEXP envir) {
  SEXP cmd = PROTECT(allocVector(VECSXP, 2));
  SET_VECTOR_ELT(cmd, 0, mkString("SUBSCRIBE"));
  SET_VECTOR_ELT(cmd, 1, channel);
  cmd = PROTECT(redis_check_command(cmd));
  SEXP ret = PROTECT(redux_redis_command(extPtr, cmd));

  redux_redis_subscribe_loop(redis_get_context(extPtr, CLOSED_ERROR),
                             callback, envir);

  UNPROTECT(3);
  return ret;
}

void redux_redis_subscribe_loop(redisContext* context,
                                SEXP callback, SEXP envir) {
  if (!isFunction(callback)) {
    error("'callback' must be a function");
  }
  if (!isEnvironment(envir)) {
    error("'envir' must be an environment");
  }
  SEXP call = PROTECT(lang2(callback, R_NilValue));
  redisReply *reply = NULL;
  int keep_going = 1;
  // Nasty:
  SEXP nms = PROTECT(allocVector(STRSXP, 3));
  SET_STRING_ELT(nms, 0, mkChar("type"));
  SET_STRING_ELT(nms, 1, mkChar("channel"));
  SET_STRING_ELT(nms, 2, mkChar("value"));

  // And we're off.  Adding a timeout here seems sensible to me as
  // that would allow for _some_ sort of interrupt checking.  I can't
  // remmeber what the timeout did though as I think it might have
  // killed the client.
  while (keep_going) {
    R_CheckUserInterrupt();
    redisGetReply(context, (void*)&reply);
    SEXP x = PROTECT(redis_reply_to_sexp(reply, REPLY_ERROR_OK));
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

SEXP redux_redis_unsubscribe(SEXP extPtr, SEXP channel) {
  redisContext *context = redis_get_context(extPtr, CLOSED_ERROR);
  // Issue the unsubscribe command:
  SEXP cmd = PROTECT(allocVector(VECSXP, 2));
  SET_VECTOR_ELT(cmd, 0, mkString("UNSUBSCRIBE"));
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
      error("Redis connection error: client likely in awkward spot");
    }
    // This is possibly over-cautious, but it doesn't really hurt.
    if (reply->type == REDIS_REPLY_ARRAY && reply->elements == 3) {
      redisReply *reply0 = reply->element[0];
      if (reply0->type == REDIS_REPLY_STRING &&
          strcmp(reply0->str, "unsubscribe") == 0) {
        break;
      }
    }
    freeReplyObject(reply);
    reply = NULL;
    n_discarded++;
    redisGetReply(context, (void*)&reply);
  }
  SEXP ret = PROTECT(redis_reply_to_sexp(reply, REPLY_ERROR_THROW));
  freeReplyObject(reply);
  if (n_discarded > 0) {
    setAttrib(ret, mkString("n_discarded"), ScalarInteger(n_discarded));
  }
  UNPROTECT(3);
  return ret;
}
