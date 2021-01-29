#include "heartbeat_interface.h"
#include "heartbeat_core.h"
#include "heartbeat_util.h"

#include <R_ext/Rdynload.h>
#include <Rversion.h>

#ifdef _WIN32
#include <winsock2.h>
#endif

static void r_heartbeat_finalize(SEXP ext_ptr);
heartbeat_payload * controller_get(SEXP ext_ptr, bool closed_error);
void throw_connection_error(heartbeat_connection_status status);

// TODO: We need to stick all this within a C++ try/catch block to
// prevent C++ exceptions bombing and dropping us out of R.  All entry
// points are in this file and it should be sufficient to consider
// this only.
SEXP r_heartbeat_create(SEXP r_host, SEXP r_port, SEXP r_password, SEXP r_db,
                        SEXP r_key, SEXP r_value, SEXP r_key_signal,
                        SEXP r_expire, SEXP r_interval, SEXP r_timeout) {
  const char
    *host = scalar_string(r_host),
    *password = scalar_string(r_password),
    *key = scalar_string(r_key),
    *value = scalar_string(r_value),
    *key_signal = scalar_string(r_key_signal);
  int
    port = scalar_integer(r_port),
    db = scalar_integer(r_db),
    expire = scalar_integer(r_expire),
    interval = scalar_integer(r_interval);
  double timeout = scalar_numeric(r_timeout);

  heartbeat_data *data = heartbeat_data_alloc(host, port, password, db,
                                              key, value, key_signal,
                                              expire, interval);
  if (data == NULL) {
    Rf_error("Failure allocating memory"); // # nocov
  }
  heartbeat_connection_status status;
  void * ptr = controller_create(data, timeout, &status);

  if (ptr == NULL) {
    throw_connection_error(status);
  }

  SEXP ext_ptr = PROTECT(R_MakeExternalPtr(ptr, R_NilValue, R_NilValue));
  R_RegisterCFinalizer(ext_ptr, r_heartbeat_finalize);
  UNPROTECT(1);
  return ext_ptr;
}

SEXP r_heartbeat_stop(SEXP ext_ptr, SEXP r_closed_error, SEXP r_wait,
                      SEXP r_timeout) {
  bool
    closed_error = scalar_logical(r_closed_error),
    wait = scalar_logical(r_wait);
  double timeout = scalar_numeric(r_timeout);
  heartbeat_payload *ptr = controller_get(ext_ptr, closed_error);
  bool exists = ptr != NULL;
  if (exists) {
    controller_stop(ptr, wait, timeout);
    R_ClearExternalPtr(ext_ptr);
  }
  return ScalarLogical(exists);
}

SEXP r_heartbeat_running(SEXP ext_ptr) {
  heartbeat_payload *ptr = controller_get(ext_ptr, false);
  return ScalarLogical(ptr != NULL);
}

void r_heartbeat_finalize(SEXP ext_ptr) {
  heartbeat_payload * ptr = controller_get(ext_ptr, false);
  if (ptr) {
    controller_stop(ptr, false, 0);
    R_ClearExternalPtr(ext_ptr);
  }
}

heartbeat_payload * controller_get(SEXP ext_ptr, bool closed_error) {
  heartbeat_payload *ptr = NULL;
  if (TYPEOF(ext_ptr) != EXTPTRSXP) {
    Rf_error("Expected an external pointer");
  }
  ptr = (heartbeat_payload*)R_ExternalPtrAddr(ext_ptr);
  if (closed_error && ptr == NULL) {
    Rf_error("heartbeat pointer already freed");
  }
  return ptr;
}

void throw_connection_error(heartbeat_connection_status status) {
  switch (status) {
  case UNSET:
  case OK:
    Rf_error("Failed to create heatbeat (unknown reason)"); // # nocov
    break;
  case FAILURE_CONNECT:
    Rf_error("Failed to create heartbeat: redis connection failed");
    break;
  case FAILURE_AUTH:
    Rf_error("Failed to create heatbeat: authentication refused");
    break;
  case FAILURE_SELECT:
    Rf_error("Failed to create heatbeat: could not SELECT db");
    break;
  case FAILURE_SET:
    Rf_error("Failed to create heatbeat: could not SET (password required?)");
    break;
  case FAILURE_ORPHAN:
    Rf_error("Failed to create heartbeat: did not come up in time");
    break;
  }
} // # nocov
