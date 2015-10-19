#include "conversions.h"

SEXP redis_reply_to_sexp(redisReply* reply, int error_action) {
  if (reply == NULL) {
    error("Failure communicating with the Redis server");
  }
  switch(reply->type) {
  case REDIS_REPLY_STATUS:
    return status_to_sexp(reply->str);
  case REDIS_REPLY_STRING:
    return (is_raw_string(reply->str, reply->len) ?
            raw_string_to_sexp(reply->str, reply->len) :
            mkString(reply->str));
  case REDIS_REPLY_INTEGER:
    return (reply->integer < INT_MAX ?
            ScalarInteger(reply->integer) :
            ScalarReal((double)reply->integer));
  case REDIS_REPLY_NIL:
    return R_NilValue;
  case REDIS_REPLY_ARRAY:
    return array_to_sexp(reply, error_action);
  case REDIS_REPLY_ERROR:
    return reply_error(reply, error_action);
  default:
    // In theory we should do something based on error action here but
    // it's also not triggerable.
    error("Unknown type");
  }
  return R_NilValue; // never get here.
}

SEXP redis_check_command(SEXP cmd) {
  if (TYPEOF(cmd) == VECSXP) {
    if (LENGTH(cmd) == 0) {
      error("argument list cannot be empty");
    }
    int np = 0;

    // First, flatten the list:
    SEXP el;
    for (int i = 0; i < LENGTH(cmd); ++i) {
      if (TYPEOF(VECTOR_ELT(cmd, i)) == VECSXP) {
        cmd = PROTECT(redis_flatten_command(cmd));
        np++;
        break;
      }
    }

    // Special checking for the first element:
    el = VECTOR_ELT(cmd, 0);
    if (TYPEOF(el) != STRSXP || LENGTH(el) == 0) {
      error("Redis command must be a non-empty character");
    }
    int dup = 0;
    for (int i = 0; i < LENGTH(cmd); ++i) {
      el = VECTOR_ELT(cmd, i);
      // Only STRSXP and RAWSXP will make it out of this look
      // unscathed (this is unfortunately not true but I'm not totally
      // sure why as it *does* make it through here but then fails on
      // a very similar call in the second stage of conversion).
      switch(TYPEOF(el)) {
      case LGLSXP:
        // Coerce logicals to ints, then to string so that TRUE -> "1"
        // and FALSE -> "0", rather than to "TRUE"/"FALSE".
        el = PROTECT(coerceVector(el, INTSXP));
        np++;
      case INTSXP:
      case REALSXP:
        el = PROTECT(coerceVector(el, STRSXP));
        np++;
        // We need to duplicate the given argument here because we're
        // going to modify the list in place.  However, if the
        // argument is not named (which will *often* the case) we can
        // skip the duplicate step too.  I'll need to make sure that
        // this works reasonably well in terms of upstream code.
        if (!dup) {
          if (NAMED(cmd) > 0) {
            cmd = PROTECT(shallow_duplicate(cmd));
            np++;
          }
          dup = 1;
        }
        SET_VECTOR_ELT(cmd, i, el);
        // Safe to unprotect straight away because these bits are
        // members of the list which is an argument, so therefore
        // protected.
        break;
      case STRSXP:
      case RAWSXP:
        continue;
      case VECSXP:
        error("Nested list element");
      default:
        // NOTE: Not recursive!
        error("Incompatible list element (element %d)", i + 1);
      }
    }
    UNPROTECT(np);
    return cmd;
  } else if (TYPEOF(cmd) == STRSXP) {
    // Note, this *has* to be STRSXP (if not VECSXP) because of the
    // conversion that a command like "GET" would have on the rest of an
    // atomic vector.
    if (LENGTH(cmd) == 0) {
      error("Redis command must be a non-empty character");
    }
    SEXP ret = PROTECT(allocVector(VECSXP, 1));
    SET_VECTOR_ELT(ret, 0, cmd);
    UNPROTECT(1);
    return ret;
  } else {
    error("Invalid type");
  }
  return R_NilValue;
}

SEXP redis_flatten_command(SEXP list) {
  const int len_in = LENGTH(list);
  int len_out = 0;
  SEXP el;
  for (int i = 0; i < len_in; ++i) {
    el = VECTOR_ELT(list, i);
    if (TYPEOF(el) == VECSXP) {
      len_out += LENGTH(el);
    } else {
      len_out++;
    }
  }
  SEXP ret = PROTECT(allocVector(VECSXP, len_out));
  for (int i = 0, j = 0; i < len_in; ++i) {
    el = VECTOR_ELT(list, i);
    if (TYPEOF(el) == VECSXP) {
      for (int k = 0; k < LENGTH(el); ++k) {
        SET_VECTOR_ELT(ret, j++, VECTOR_ELT(el, k));
      }
    } else {
      SET_VECTOR_ELT(ret, j++, el);
    }
  }

  UNPROTECT(1);
  return ret;
}

SEXP redis_check_list(SEXP list) {
  SEXP ret = PROTECT(shallow_duplicate(list));
  for (int i = 0; i < LENGTH(list); ++i) {
    SET_VECTOR_ELT(ret, i, redis_check_command(VECTOR_ELT(list, i)));
  }
  UNPROTECT(1);
  return ret;
}

/* NOTE: We assume that the command has been passed through
   `redis_check_command` and operate with that assumption in mind */
size_t sexp_to_redis(SEXP cmd, const char ***p_argv, size_t **p_argvlen) {
  size_t argc = 0;
  for (int i = 0; i < LENGTH(cmd); ++i) {
    SEXP el = VECTOR_ELT(cmd, i);
    argc += TYPEOF(el) == STRSXP ? LENGTH(el) : 1;
  }

  const char **argv = (const char**) R_alloc(argc, sizeof(const char*));
  size_t *argvlen = (size_t*) R_alloc(argc, sizeof(size_t));
  size_t k = 0;
  for (int i = 0; i < LENGTH(cmd); ++i) {
    SEXP cmd_i = VECTOR_ELT(cmd, i);
    int type_i = TYPEOF(cmd_i);
    if (type_i == STRSXP) {
      for (int j = 0; j < LENGTH(cmd_i); ++j, ++k) {
        argv[k] = CHAR(STRING_ELT(cmd_i, j));
        argvlen[k] = LENGTH(STRING_ELT(cmd_i, j));
      }
    } else if (type_i == RAWSXP) {
      argv[k] = (char *)RAW(cmd_i);
      argvlen[k] = LENGTH(cmd_i);
      k++;
    } else {
      error("Unexpected type");
    }
  }

  *p_argv = argv;
  *p_argvlen = argvlen;
  return argc;
}

// I don't know that 'X\n' is going to be enough to *really* store
// this as binary data, but perhaps it will be enough.  If I don't
// want interoperability with RcppRedis I could pad that with more
// information and strip it off.  For now this will do.
//
// I think I'll add my own thing and that allows storing of
// *arbitrary* binary data.
//
// This idea could be expanded to allow a flag to indicate if the
// data should be serialised/deserialised automatically.
//
// Another thing worth checking here is for the existence of a null
// byte.  Empirically this turns up as character three in an R
// serialised string.
int is_raw_string(char* str, size_t len) {
  if (len > 2 && str[0] == 'X' && str[1] == '\n') {
    for (size_t i = 0; i < len; ++i) {
      if (str[i] == '\0') {
        return 1;
      }
    }
    return 0;
  } else {
    return 0;
  }
}
SEXP raw_string_to_sexp(char* str, size_t len) {
  SEXP ret = PROTECT(allocVector(RAWSXP, len));
  memcpy(RAW(ret), str, len);
  UNPROTECT(1);
  return ret;
}
SEXP status_to_sexp(char* str) {
  SEXP ret = PROTECT(mkString(str));
  setAttrib(ret, R_ClassSymbol, mkString("redis_status"));
  UNPROTECT(1);
  return ret;
}
SEXP array_to_sexp(redisReply* reply, int error_action) {
  SEXP ret = PROTECT(allocVector(VECSXP, reply->elements));
  size_t i;
  for (i = 0; i < reply->elements; ++i) {
    SET_VECTOR_ELT(ret, i,
                   redis_reply_to_sexp(reply->element[i], error_action));
  }
  UNPROTECT(1);
  return ret;
}

SEXP reply_error(redisReply* reply, int error_action) {
  SEXP ret = NULL;
  if (error_action == REPLY_ERROR_THROW) {
    char * msg = (char*) R_alloc(reply->len + 1, sizeof(const char));
    memcpy(msg, reply->str, reply->len);
    msg[reply->len] = '\0';
    freeReplyObject(reply);
    error(msg);
    return ret;
  } else { // REPLY_ERROR_OK
    SEXP ret = PROTECT(mkString(reply->str));
    setAttrib(ret, R_ClassSymbol, mkString("redis_error"));
    UNPROTECT(1);
    return ret;
  }
}
