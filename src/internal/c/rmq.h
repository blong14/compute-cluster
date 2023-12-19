#ifndef RMQ_H
#define RMQ_H

#include <stdbool.h>

#include "amqp.h"

typedef struct {
    const char* host;
    const char* port;
    const char* user;
    const char* password;
    const char* queue;
} rmq_env;

rmq_env new_rmq_env(void);

amqp_connection_state_t rmq_connect(rmq_env);

void rmq_close(amqp_connection_state_t conn, amqp_bytes_t queue);

amqp_bytes_t rmq_queue_declare(amqp_connection_state_t, const char* queue);

bool rmq_check_rpc_reply(const amqp_rpc_reply_t*);

#endif //RMQ_H
