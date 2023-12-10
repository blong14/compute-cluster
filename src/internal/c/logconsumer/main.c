#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include "amqp.h"
#include "amqp_tcp_socket.h"

typedef struct {
    const char* host;
    const char* port;
    const char* user;
    const char* password;
    const char* queue;
} rmq_env;

amqp_connection_state_t rmq_connect(rmq_env);

amqp_bytes_t rmq_declare(amqp_connection_state_t, const char* queue);

void rmq_consume(amqp_connection_state_t, amqp_bytes_t);

void rmq_close(amqp_connection_state_t, amqp_bytes_t);

bool rmq_check_reply(const amqp_rpc_reply_t*);

rmq_env new_rmq_env(void);

int main(void) {
    const rmq_env env = new_rmq_env();

    const amqp_connection_state_t conn = rmq_connect(env);

    const amqp_bytes_t queuename = rmq_declare(conn, env.queue);

    rmq_consume(conn, queuename);

    rmq_close(conn, queuename);

    return EXIT_SUCCESS;
}

amqp_connection_state_t rmq_connect(const rmq_env env) {
    amqp_connection_state_t conn;
    amqp_socket_t* socket;

    printf("opening socket @ amqp://%s:%s\n", env.host, env.port);

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
        printf("%d/n", status);
        exit(status);
    }

    const amqp_rpc_reply_t login_reply = amqp_login(
        conn, "/", 0, AMQP_DEFAULT_FRAME_SIZE, 0, AMQP_SASL_METHOD_PLAIN, env.user, env.password);
    if (!rmq_check_reply(&login_reply)) {
        perror("error logging in");
        exit(EXIT_FAILURE);
    }

    amqp_channel_open(conn, 1);
    const amqp_rpc_reply_t chn_open_reply = amqp_get_rpc_reply(conn);
    if (!rmq_check_reply(&chn_open_reply)) {
        perror("error opening channel");
        exit(EXIT_FAILURE);
    }

    return conn;
}

amqp_bytes_t rmq_declare(const amqp_connection_state_t conn, const char* queue) {
    const amqp_queue_declare_ok_t* queue_declare_ok = amqp_queue_declare(
        conn, 1, amqp_cstring_bytes(queue), 0, 0, 0, 1, amqp_empty_table);
    const amqp_rpc_reply_t reply = amqp_get_rpc_reply(conn);
    if (!rmq_check_reply(&reply)) {
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

void rmq_consume(amqp_connection_state_t conn, amqp_bytes_t queuename) {
    fprintf(stdout, "consuming on %s\n", (const char *) queuename.bytes);

    amqp_basic_consume(conn, 1, queuename, amqp_empty_bytes, 0, 1, 0,
                       amqp_empty_table);
    const amqp_rpc_reply_t cns_reply = amqp_get_rpc_reply(conn);
    if (!rmq_check_reply(&cns_reply)) {
        perror("error in basic consume");
        exit(EXIT_FAILURE);
    }

    amqp_frame_t frame;

    for (;;) {
        amqp_rpc_reply_t ret;
        amqp_envelope_t envelope;

        amqp_maybe_release_buffers(conn);

        ret = amqp_consume_message(conn, &envelope, NULL, 0);
        if (!rmq_check_reply(&ret)) {
            if (AMQP_RESPONSE_LIBRARY_EXCEPTION == ret.reply_type &&
                AMQP_STATUS_UNEXPECTED_STATE == ret.library_error) {
                if (AMQP_STATUS_OK != amqp_simple_wait_frame(conn, &frame)) {
                    return;
                }

                if (AMQP_FRAME_METHOD == frame.frame_type) {
                    switch (frame.payload.method.id) {
                        case AMQP_CHANNEL_CLOSE_METHOD:
                            /* a channel.close method happens when a channel exception occurs,
                             * this can happen by publishing to an exchange that doesn't exist
                             * for example.
                             *
                             * In this case you would need to open another channel redeclare
                             * any queues that were declared auto-delete, and restart any
                             * consumers that were attached to the previous channel.
                             */
                            return;
                        case AMQP_CONNECTION_CLOSE_METHOD:
                            /* a connection.close method happens when a connection exception
                             * occurs, this can happen by trying to use a channel that isn't
                             * open for example.
                             *
                             * In this case the whole connection must be restarted.
                             */
                            return;
                        default:
                            fprintf(stderr, "An unexpected method was received %u", frame.payload.method.id);
                            return;
                    }
                }
            }
        } else {
            amqp_bytes_t body = envelope.message.body;
            if (!amqp_basic_ack(conn, envelope.channel, envelope.delivery_tag, 0)) {
                fprintf(stderr, "basic ack failed %s\n", (const char *) body.bytes);
            }
            fprintf(stdout, "message received %s\n", (const char *) body.bytes);
            amqp_destroy_envelope(&envelope);
        }
    }
}

void rmq_close(amqp_connection_state_t conn, amqp_bytes_t queuename) {
    amqp_bytes_free(queuename);
    amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS);
    amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
    amqp_destroy_connection(conn);
}

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

bool rmq_check_reply(const amqp_rpc_reply_t* reply) {
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
