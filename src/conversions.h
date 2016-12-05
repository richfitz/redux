#include <R.h>
#include <Rinternals.h>
#include <hiredis/hiredis.h>
#include <stdbool.h>

#define REPLY_ERROR_OK 0
#define REPLY_ERROR_THROW 1

/* whole reply */
SEXP redis_reply_to_sexp(redisReply* reply, int error_action);

/* possible bits of a reply */
SEXP raw_string_to_sexp(const char* s, size_t len);
SEXP status_to_sexp(const char* s);
SEXP array_to_sexp(redisReply* reply, int error_action);
SEXP reply_error(redisReply* reply, int error_action);

/* detection */
bool is_raw_string(const char* str, size_t len);
/* to redis */
SEXP redis_check_command(SEXP cmd);
SEXP redis_flatten_command(SEXP list);
SEXP redis_check_list(SEXP list);
void sexp_check_types(SEXP cmd);
size_t sexp_to_redis(SEXP cmd, const char ***p_argv, size_t **p_argvlen);
