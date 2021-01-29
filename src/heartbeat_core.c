#include "heartbeat_core.h"
#include "tinycthread.h"
#include "heartbeat_util.h"

#include <math.h>

#ifndef __WIN32
#include <signal.h>
#include <unistd.h>
#endif

heartbeat_data * heartbeat_data_alloc(const char *host, int port,
                                      const char *password, int db,
                                      const char *key, const char *value,
                                      const char *key_signal,
                                      int expire, int interval) {
  heartbeat_data * ret = (heartbeat_data*) calloc(1, sizeof(heartbeat_data));
  if (ret == NULL) {
    // This is only the case when there is a failure in the allocator
    // allocating a single element (so probably not very common)
    return NULL; // # nocov
  }
  ret->host = string_duplicate_c(host);
  ret->port = port;
  if (strlen(password) == 0) {
    ret->password = NULL;
  } else {
    ret->password = string_duplicate_c(password);
  }
  ret->db = db;
  ret->key = string_duplicate_c(key);
  ret->value = string_duplicate_c(value);
  ret->key_signal = string_duplicate_c(key_signal);
  ret->expire = expire;
  ret->interval = interval;
  return ret;
}

void heartbeat_data_free(heartbeat_data * data) {
  if (data) {
    free((void*) data->host);
    if (data->password != NULL) {
      free((void*) data->password);
    }
    free((void*) data->key);
    free((void*) data->value);
    free((void*) data->key_signal);
    free(data);
  }
}

redisContext * heartbeat_connect(const heartbeat_data * data,
                                 heartbeat_connection_status * status) {
  redisContext *con = redisConnect(data->host, data->port);
  if (con->err) {
    *status = FAILURE_CONNECT;
    // If running into trouble, it may be useful to print the error like so:
    //
    //   REprintf("Redis connection failure: %s", con->errstr);
    //
    // However, this will not end up in the actual error message and
    // may be hard to capture, suppress or work with.
    redisFree(con);
    return NULL;
  }
  if (data->password != NULL) {
    redisReply *reply = (redisReply*)
      redisCommand(con, "AUTH %s", data->password);
    bool error = reply == NULL || reply->type == REDIS_REPLY_ERROR;
    if (reply) {
      freeReplyObject(reply);
    }
    if (error) {
      *status = FAILURE_AUTH;
      redisFree(con);
      return NULL;
    }
  }
  if (data->db != 0) {
    redisReply *reply = (redisReply*) redisCommand(con, "SELECT %d", data->db);
    bool error = reply == NULL || reply->type == REDIS_REPLY_ERROR;
    if (reply) {
      *status = FAILURE_SELECT;
      freeReplyObject(reply);
    }
    if (error) {
      redisFree(con);
      return NULL;
    }
  }
  return con;
}

int worker_create_wrapper(void * x) {
  return worker_create((heartbeat_payload*) x);
}

int worker_create(heartbeat_payload *x) {
  x->con = worker_init(x->data, &(x->status));
  x->started = x->con != NULL;
  if (!x->started) {
    x->keep_going = false;
    heartbeat_data_free(x->data);
    x->data = NULL;
    return 1;
  }
  worker_loop(x);
  worker_cleanup(x->con, x->data);
  heartbeat_data_free(x->data);
  x->data = NULL;
  x->stopped = true;
  if (x->orphaned) {
    free(x);
  }
  return 0;
}

void worker_loop(heartbeat_payload *x) {
  while (x->keep_going) {
    worker_run_alive(x->con, x->data);
    int signal = worker_run_poll(x->con, x->data);
    if (signal > 0) {
#ifndef __WIN32
      kill(getpid(), signal);
#endif
    }
  }
}

redisContext * worker_init(const heartbeat_data *data,
                           heartbeat_connection_status * status) {
  redisContext *con = heartbeat_connect(data, status);
  if (!con) {
    return NULL;
  }
  redisReply *reply = (redisReply*)
    redisCommand(con, "SET %s %s EX %d", data->key, data->value, data->expire);
  bool error = reply == NULL || reply->type == REDIS_REPLY_ERROR;
  if (reply) {
    freeReplyObject(reply);
  }
  if (error) {
    *status = FAILURE_SET;
    redisFree(con);
    return NULL;
  }
  return con;
}

void worker_cleanup(redisContext *con, const heartbeat_data *data) {
  redisReply *reply = (redisReply*)
    redisCommand(con, "DEL %s", data->key);
  if (reply) {
    freeReplyObject(reply);
  }
}

void worker_run_alive(redisContext *con, const heartbeat_data * data) {
  redisReply *reply = (redisReply*)
    redisCommand(con, "EXPIRE %s %d", data->key, data->expire);
  if (reply) {
    freeReplyObject(reply);
  }
}

int worker_run_poll(redisContext *con, const heartbeat_data * data) {
  redisReply *reply = (redisReply*)
    redisCommand(con, "BLPOP %s %d", data->key_signal, data->interval);
  int ret = 0;
  if (reply &&
      reply->type == REDIS_REPLY_ARRAY &&
      reply->elements == 2) {
    ret = atoi(reply->element[1]->str);
  }
  if (reply) {
    freeReplyObject(reply);
  }
  return ret;
}

// All the thready bits down here
void sleep_ms(int duration) {
  struct timespec interval = {0, duration * 1e6};
  thrd_sleep(&interval, NULL);
}

heartbeat_payload * controller_create(heartbeat_data *data, double timeout,
                            heartbeat_connection_status *status) {
  // I do not know what in here is throwable but in general I can't
  // have things throwing!  This might all need to go in a big
  // try/catch.
  heartbeat_payload * x = (heartbeat_payload*) calloc(1, sizeof(heartbeat_payload));
  x->data = data;
  x->con = NULL;
  x->started = false;
  x->stopped = false;
  x->orphaned = false;
  x->keep_going = true;
  x->status = UNSET;

  thrd_t thread;
  thrd_create(&thread, worker_create_wrapper, x);
  thrd_detach(thread);

  // Wait for things to come up
  size_t time_poll = 10; // must go into 1000 nicely
  size_t timeout_ms = ceil(timeout * 1000);
  size_t n = timeout_ms / time_poll;
  for (size_t i = 0; i < n; ++i) {
    if (x->started) {
      *status = OK;
      return x;
    } else if (!x->keep_going) {
      *status = x->status;
      free(x);
      x = NULL;
      break;
    }

    sleep_ms(time_poll);
  }
  // We did not come up in time!
  if (x) {
    *status = FAILURE_ORPHAN;
    x->orphaned = false;
    x->keep_going = false;
  }
  return NULL;
}

bool controller_stop(heartbeat_payload *x, bool wait, double timeout) {
  bool ret = false;
  if (x) {
    heartbeat_connection_status status;
    redisContext * con = heartbeat_connect(x->data, &status);
    const char *key_signal = string_duplicate_c(x->data->key_signal);

    if (!wait) {
      x->orphaned = true;
    }
    x->keep_going = false;
    if (con) {
      redisReply *r = (redisReply*) redisCommand(con, "RPUSH %s 0", key_signal);
      if (r) {
        freeReplyObject(r);
      }
      redisFree(con);
    }
    if (wait) {
      size_t time_poll = 10; // must go into 1000 nicely
      size_t timeout_ms = ceil(timeout * 1000);
      size_t n = timeout_ms / time_poll;
      for (size_t i = 0; i < n; ++i) {
        if (x->stopped) {
          free(x);
          ret = true;
          break;
        }
        sleep_ms(time_poll);
      }
    }
    free((void*) key_signal);
  }
  return ret;
}
