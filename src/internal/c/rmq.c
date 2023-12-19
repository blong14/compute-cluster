#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>

#include "amqp.h"
#include "amqp_tcp_socket.h"

#include "rmq.h"

rmq_env new_rmq_env(void) {
    rmq_env env;
    const char *host, *port, *user, *password, *queue;

    if ((host = getenv("RMQ_HOST")) == NULL)
        host = "localhost";

    if ((port = getenv("RMQ_PORT")) == NULL)
        port = "5672";

    if ((user = getenv("RMQ_USER")) == NULL)
        user = "guest";

    if ((password = getenv("RMQ_PASSWORD")) == NULL)
        password = "guest";

    if ((queue = getenv("RMQ_QUEUE")) == NULL)
        queue = "log";

    env.host = host;
    env.port = port;
    env.user = user;
    env.password = password;
    env.queue = queue;

    return env;
}

amqp_connection_state_t rmq_connect(const rmq_env env) {
    amqp_connection_state_t conn;
    amqp_socket_t* socket;

    if ((conn = amqp_new_connection()) == NULL) {
        perror("error creating connection");
        exit(EXIT_FAILURE);
    }

    if ((socket = amqp_tcp_socket_new(conn)) == NULL) {
        perror("error creating TCP socket");
        exit(EXIT_FAILURE);
    }

    const int status = amqp_socket_open(socket, env.host, atoi(env.port));
    if (status != AMQP_STATUS_OK) {
        perror("error opening TCP socket");
        exit(status);
    }

    const amqp_rpc_reply_t login_reply = amqp_login(
        conn, "/", 0, AMQP_DEFAULT_FRAME_SIZE, 0, AMQP_SASL_METHOD_PLAIN, env.user, env.password);
    if (!rmq_check_rpc_reply(&login_reply)) {
        perror("error logging in");
        exit(EXIT_FAILURE);
    }

    amqp_channel_open(conn, 1);
    const amqp_rpc_reply_t chn_open_reply = amqp_get_rpc_reply(conn);
    if (!rmq_check_rpc_reply(&chn_open_reply)) {
        perror("error opening channel");
        exit(EXIT_FAILURE);
    }

    return conn;
}

void rmq_close(amqp_connection_state_t conn, amqp_bytes_t queuename) {
    amqp_bytes_free(queuename);
    amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS);
    amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
    amqp_destroy_connection(conn);
}

amqp_bytes_t rmq_queue_declare(amqp_connection_state_t conn, const char* queue) {
    const amqp_queue_declare_ok_t* queue_declare_ok = amqp_queue_declare(
        conn, 1, amqp_cstring_bytes(queue), 0, 0, 0, 1, amqp_empty_table);
    const amqp_rpc_reply_t reply = amqp_get_rpc_reply(conn);
    if (!rmq_check_rpc_reply(&reply)) {
        perror("error declaring queue");
        exit(EXIT_FAILURE);
    }

    const amqp_bytes_t queuename = amqp_bytes_malloc_dup(queue_declare_ok->queue);
    if (queuename.bytes == NULL) {
        perror("out of memory while copying queue name");
        exit(EXIT_FAILURE);
    }

    return queuename;
}

bool rmq_check_rpc_reply(const amqp_rpc_reply_t* reply) {
    switch (reply->reply_type) {
        case AMQP_RESPONSE_NORMAL:
            return true;
        case AMQP_RESPONSE_SERVER_EXCEPTION:
            fprintf(stderr, "AMQP server exception\n");
            return false;
        case AMQP_RESPONSE_LIBRARY_EXCEPTION:
            fprintf(stderr, "AMQP library exception\n");
            return false;
        default:
            fprintf(stderr, "AMQP unknown exception\n");
            return false;
    }
}
