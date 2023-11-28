#include "conversions.h"

SEXP redis_reply_to_sexp(redisReply* reply, bool error_throw) {
  if (reply == NULL) {
    error("Failure communicating with the Redis server");
  }
  switch(reply->type) {
  case REDIS_REPLY_STATUS:
    return status_to_sexp(reply->str);
  case REDIS_REPLY_STRING:
    return raw_string_to_sexp(reply->str, reply->len);
  case REDIS_REPLY_INTEGER:
    return (reply->integer < INT_MAX ?
            ScalarInteger(reply->integer) :
            ScalarReal((double)reply->integer));
  case REDIS_REPLY_NIL:
    return R_NilValue;
  case REDIS_REPLY_ARRAY:
    return array_to_sexp(reply, error_throw);
  case REDIS_REPLY_ERROR:
    return reply_error(reply, error_throw);
  default:
    // In theory we should do something based on error action here but
    // it's also not triggerable.
    error("Unknown type [redux bug -- please report]"); // # nocov
  }
  return R_NilValue; // # nocov
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
      // Only STRSXP, RAWSXP and NILSXP will make it out of this loop
      // unscathed.
      switch(TYPEOF(el)) {
      case LGLSXP:
        // Coerce logicals to ints, then to string so that TRUE -> "1"
        // and FALSE -> "0", rather than to "TRUE"/"FALSE".
        el = PROTECT(coerceVector(el, INTSXP));
        np++;
        // fall through
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
          if (MAYBE_REFERENCED(cmd)) {
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
      case NILSXP:
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
    switch(TYPEOF(el)) {
    case VECSXP:
      len_out += LENGTH(el);
      break;
    case LGLSXP:
    case INTSXP:
    case REALSXP:
    case STRSXP:
    case RAWSXP:
      len_out++;
      break;
      // Don't allocate space for NULL values here.  TODO: check that
      // this is all OK
    case NILSXP:
      break;
    default:
      error("unexpected type (element %d)", i); // # nocov
    }
  }
  SEXP ret = PROTECT(allocVector(VECSXP, len_out));
  for (int i = 0, j = 0; i < len_in; ++i) {
    el = VECTOR_ELT(list, i);
    const int type_el = TYPEOF(el);
    if (type_el == VECSXP) {
      for (int k = 0; k < LENGTH(el); ++k) {
        SET_VECTOR_ELT(ret, j++, VECTOR_ELT(el, k));
      }
    } else if (type_el != NILSXP) { // STRSXP, RAWSXP
      SET_VECTOR_ELT(ret, j++, el);
    } // skips over NULL
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
    const int type_el = TYPEOF(el);
    argc += type_el == STRSXP ? LENGTH(el) : type_el == NILSXP ? 0 : 1;
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
    } else if (type_i != NILSXP) {
      error("Unexpected type (2) [redux bug -- please report]"); // # nocov
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
// *arbitrary* binary data.  Perhaps add a separate 2 byte header?
//
// This idea could be expanded to allow a flag to indicate if the
// data should be serialised/deserialised automatically.
//
// Another thing worth checking here is for the existence of a null
// byte.  Empirically this turns up as character three in an R
// serialised string.
bool is_raw_string(const char* str, size_t len) {
  if (len > 2) {
    if ((str[0] == 'X' || str[0] == 'B') && str[1] == '\n') {
      for (size_t i = 0; i < len; ++i) {
        if (str[i] == '\0') {
          return true;
        }
      }
    }
  }
  return false;
}

SEXP raw_string_to_sexp(const char* str, size_t len) {
  // There are different approaches here to detecting a raw string; we
  // can test for presence of a nul byte, but that involves a
  // traversal of _every_ string.  It really should be corect though
  // as every serialisation header will contain a nul byte.
  //
  // The strategy here is to check for a serialised object, then
  // assume a string, but fall back on re-encoding as RAW (with an
  // extra copy) if a nul byte is found
  bool is_raw = is_raw_string(str, len);
  SEXP ret;
  if (is_raw) {
    ret = PROTECT(allocVector(RAWSXP, len));
    memcpy(RAW(ret), str, len);
    UNPROTECT(1);
  } else {
    ret = PROTECT(mkString(str));
    const size_t slen = LENGTH(STRING_ELT(ret, 0));
    if (slen < len) {
      ret = PROTECT(allocVector(RAWSXP, len));
      memcpy(RAW(ret), str, len);
      UNPROTECT(2);
    } else {
      UNPROTECT(1);
    }
  }
  return ret;
}

SEXP status_to_sexp(const char* str) {
  SEXP ret = PROTECT(mkString(str));
  setAttrib(ret, R_ClassSymbol, mkString("redis_status"));
  UNPROTECT(1);
  return ret;
}

SEXP array_to_sexp(redisReply* reply, bool error_throw) {
  SEXP ret = PROTECT(allocVector(VECSXP, reply->elements));
  size_t i;
  for (i = 0; i < reply->elements; ++i) {
    SET_VECTOR_ELT(ret, i,
                   redis_reply_to_sexp(reply->element[i], error_throw));
  }
  UNPROTECT(1);
  return ret;
}

SEXP reply_error(redisReply* reply, bool error_throw) {
  SEXP ret = NULL;
  if (error_throw) {
    char * msg = (char*) R_alloc(reply->len + 1, sizeof(const char));
    memcpy(msg, reply->str, reply->len);
    msg[reply->len] = '\0';
    freeReplyObject(reply);
    error("%s", msg);
    return ret;
  } else { // pass error back as object
    SEXP ret = PROTECT(mkString(reply->str));
    setAttrib(ret, R_ClassSymbol, mkString("redis_error"));
    UNPROTECT(1);
    return ret;
  }
}
