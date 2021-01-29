#ifndef REDUX_HEARTBEAT_CORE_H
#define REDUX_HEARTBEAT_CORE_H

#include <hiredis.h>
#include <stdbool.h>

// This is the bits required to communicate with Redis; the
// connection, keys and timing information.
typedef struct heartbeat_data {
  const char * host;
  int port;
  const char * password;
  int db;
  const char * key;
  const char * key_signal;
  const char * value;
  int expire;
  int interval;
} heartbeat_data;

typedef enum {
  UNSET,
  OK,
  FAILURE_CONNECT,
  FAILURE_AUTH,
  FAILURE_SELECT,
  FAILURE_SET,
  FAILURE_ORPHAN
} heartbeat_connection_status;

// This will hold both the allocated heartbeat data object and a
// shared flag that will be used to communicate between the processes.
typedef struct heartbeat_payload {
  heartbeat_data *data;
  redisContext *con;
  bool started;
  bool keep_going;
  bool stopped;
  bool orphaned;
  heartbeat_connection_status status;
} heartbeat_payload;


heartbeat_data * heartbeat_data_alloc(const char *host, int port,
                                      const char *password, int db,
                                      const char *key, const char *value,
                                      const char *key_signal,
                                      int expire, int interval);
void heartbeat_data_free(heartbeat_data * obj);

redisContext * heartbeat_connect(const heartbeat_data *data,
                                 heartbeat_connection_status * status);

int worker_create(heartbeat_payload *x);
void worker_loop(heartbeat_payload *x);

redisContext * worker_init(const heartbeat_data *data,
                           heartbeat_connection_status * status);
void worker_cleanup(redisContext *con, const heartbeat_data *data);
void worker_run_alive(redisContext *con, const heartbeat_data *data);
int worker_run_poll(redisContext *con, const heartbeat_data *data);

heartbeat_payload * controller_create(heartbeat_data *data, double timeout,
                            heartbeat_connection_status *status);
bool controller_stop(heartbeat_payload *x, bool wait, double timeout);

#endif
