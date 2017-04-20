#include <R.h>
#include <Rinternals.h>
#include <hiredis/hiredis.h>
#include <stdbool.h>

/* whole reply */
SEXP redis_reply_to_sexp(redisReply* reply, bool error_throw);

/* possible bits of a reply */
SEXP raw_string_to_sexp(const char* s, size_t len);
SEXP status_to_sexp(const char* s);
SEXP array_to_sexp(redisReply* reply, bool error_throw);
SEXP reply_error(redisReply* reply, bool error_throw);

/* detection */
bool is_raw_string(const char* str, size_t len);
/* to redis */
SEXP redis_check_command(SEXP cmd);
SEXP redis_flatten_command(SEXP list);
SEXP redis_check_list(SEXP list);
void sexp_check_types(SEXP cmd);
size_t sexp_to_redis(SEXP cmd, const char ***p_argv, size_t **p_argvlen);
