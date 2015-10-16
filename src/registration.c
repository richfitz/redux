#include "redux.h"
#include "conversions.h"
#include <R_ext/Rdynload.h>

static const R_CallMethodDef callMethods[] = {
  {"Credux_redis_connect",       (DL_FUNC) &redux_redis_connect,        2},
  {"Credux_redis_connect_unix",  (DL_FUNC) &redux_redis_connect_unix,   1},

  {"Credux_redis_command",       (DL_FUNC) &redux_redis_command,        2},

  {"Credux_redis_pipeline",      (DL_FUNC) &redux_redis_pipeline,       2},

  {"Credux_redis_subscribe",     (DL_FUNC) &redux_redis_subscribe,      4},
  {"Credux_redis_unsubscribe",   (DL_FUNC) &redux_redis_unsubscribe,    2},

  {NULL,                         NULL,                                  0}
};

void R_init_redux(DllInfo *info) {
  R_registerRoutines(info, NULL, callMethods, NULL, NULL);
}
