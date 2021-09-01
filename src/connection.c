#include "connection.h"
#include "conversions.h"

static void redis_finalize(SEXP extPtr);
char * string_duplicate(const char * x);

// API functions first:
SEXP redux_redis_connect(SEXP host, SEXP port) {
  redisContext *context = redisConnect(CHAR(STRING_ELT(host, 0)),
                                       INTEGER(port)[0]);
  if (context == NULL) {
    error("Creating context failed catastrophically [tcp]"); // # nocov
  }
  if (context->err != 0) {
    const char * errstr = string_duplicate(context->errstr);
    redisFree(context);
    error("Failed to create context: %s", errstr);
  }
  SEXP extPtr = PROTECT(R_MakeExternalPtr(context, host, R_NilValue));
  R_RegisterCFinalizer(extPtr, redis_finalize);
  UNPROTECT(1);
  return extPtr;
}

SEXP redux_redis_connect_ssl(SEXP host, SEXP port, SEXP CApath, 
                             SEXP CERTpath, SEXP KEYpath) {

  // hiredis SSL connection context and error var
  redisSSLContext *redis_ssl_context;
  redisSSLContextError redis_ssl_error;

  // Initialise OpenSSL
  redisInitOpenSSL();

  // Set up the SSL connection parameters
  redis_ssl_context = redisCreateSSLContext(
    CHAR(STRING_ELT(CApath, 0)),
    NULL, /* not providing path to trusted certs */
    CHAR(STRING_ELT(CERTpath, 0)), 
    CHAR(STRING_ELT(KEYpath, 0)), 
    CHAR(STRING_ELT(host, 0)),
    &redis_ssl_error);

  if(redis_ssl_context == NULL || redis_ssl_error != 0) {
    error("Failed to create SSL context: %s\n",
      (redis_ssl_error != 0) ? 
        redisSSLContextGetError(redis_ssl_error) : "Unknown error");
  }

  // Initiate a connection with redis
  redisContext *context = redisConnect(CHAR(STRING_ELT(host, 0)),
                                       INTEGER(port)[0]);
  if (context == NULL) {
    error("Creating context failed catastrophically [tcp_ssl]"); // # nocov
  }
  if (context->err != 0) {
    const char * errstr = string_duplicate(context->errstr);
    redisFree(context);
    
    error("Failed to create context: %s", errstr);
  }

  // Now we have a connection established, we can negotiate the SSL connection
  if (redisInitiateSSLWithContext(context, redis_ssl_context) != REDIS_OK) {
        redisFreeSSLContext(redis_ssl_context);
        if (context->err != 0) {
          const char * errstr_ssl = string_duplicate(context->errstr);
          redisFree(context);
          error("Failed to initialize SSL connection: %s\n", errstr_ssl);
        }
        redisFree(context);
        error("Failed to initialize SSL connection\n");
  }
  SEXP extPtr = PROTECT(R_MakeExternalPtr(context, host, R_NilValue));
  R_RegisterCFinalizer(extPtr, redis_finalize);
  UNPROTECT(1);
  return extPtr;
}

SEXP redux_redis_connect_unix(SEXP path) {
  redisContext *context = redisConnectUnix(CHAR(STRING_ELT(path, 0)));
  if (context == NULL) {
    error("Creating context failed catastrophically [unix]"); // # nocov
  }
  if (context->err != 0) {
    const char * errstr = string_duplicate(context->errstr);
    redisFree(context);
    error("Failed to create context: %s", errstr);
  }
  SEXP extPtr = PROTECT(R_MakeExternalPtr(context, path, R_NilValue));
  R_RegisterCFinalizer(extPtr, redis_finalize);
  UNPROTECT(1);
  return extPtr;
}

SEXP redux_redis_command(SEXP extPtr, SEXP cmd) {
  redisContext *context = redis_get_context(extPtr, true);

  cmd = PROTECT(redis_check_command(cmd));
  const char **argv = NULL;
  size_t *argvlen = NULL;
  const size_t argc = sexp_to_redis(cmd, &argv, &argvlen);

  redisReply *reply = redisCommandArgv(context, argc, argv, argvlen);
  SEXP ret = PROTECT(redis_reply_to_sexp(reply, true));
  freeReplyObject(reply);
  UNPROTECT(2);
  return ret;
}

// I don't think that append/get reply are safe from R because it's
// too easy to lock the process up.  So focus instead on a "pipline"
// operation that has some reasonable guarantees about R errors.
SEXP redux_redis_pipeline(SEXP extPtr, SEXP list) {
  redisContext *context = redis_get_context(extPtr, true);

  // Now, try and do the basic processing of *all* commands before
  // sending any.
  list = PROTECT(redis_check_list(list));
  const size_t nc = LENGTH(list);
  const char ***argv = (const char***) R_alloc(nc, sizeof(const char**));
  size_t **argvlen = (size_t**) R_alloc(nc, sizeof(size_t*));
  size_t *argc = (size_t*) R_alloc(nc, sizeof(size_t));
  for (size_t i = 0; i < nc; ++i) {
    argc[i] = sexp_to_redis(VECTOR_ELT(list, i), argv + i, argvlen + i);
  }

  for (size_t i = 0; i < nc; ++i) {
    redisAppendCommandArgv(context, argc[i], argv[i], argvlen[i]);
  }

  redisReply *reply = NULL;
  SEXP ret = PROTECT(allocVector(VECSXP, nc));
  for (size_t i = 0; i < nc; ++i) {
    redisGetReply(context, (void*)&reply);
    SET_VECTOR_ELT(ret, i, redis_reply_to_sexp(reply, false));
    freeReplyObject(reply);
  }
  UNPROTECT(2);
  return ret;
}

// Internal functions:
redisContext* redis_get_context(SEXP extPtr, bool closed_error) {
  // It is not possible here to be *generally* typesafe, short of
  // adding (and checking at every command) that we have an external
  // pointer to the correct type.  So cross fingers and hope for the
  // best which is what most packages do I believe.  We can, however,
  // check that we're getting a pointer from the correct sort of
  // thing, and that the pointer is not NULL.
  void *context = NULL;
  if (TYPEOF(extPtr) != EXTPTRSXP) {
    error("Expected an external pointer");
  }
  context = (redisContext*) R_ExternalPtrAddr(extPtr);
  if (!context && closed_error) {
    error("Context is not connected");
  }
  return context;
}

static void redis_finalize(SEXP extPtr) {
  redisContext *context = redis_get_context(extPtr, false);
  if (context) {
    redisFree(context);
    R_ClearExternalPtr(extPtr);
  }
}

char * string_duplicate(const char * x) {
  const size_t n = strlen(x);
  char * ret = (char*) R_alloc(n + 1, sizeof(char));
  strcpy(ret, x);
  return ret;
}
