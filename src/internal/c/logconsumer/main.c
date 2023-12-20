#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>

#include "amqp.h"
#include "cjson/cJSON.h"

#include "../log.h"
#include "../rmq.h"

void rmq_consume();

void sig_handler(int);

amqp_connection_state_t conn;
amqp_bytes_t queuename;

int main(void) {
    struct sigaction sa;
    sa.sa_handler = sig_handler;

    int const signals[4] = {SIGHUP, SIGINT, SIGTERM, SIGQUIT};
    for (int i = 0; i < 4; i++) {
        if (sigaction(signals[i], &sa, NULL) == -1) {
            perror("signal handling error");
            exit(EXIT_FAILURE);
        }
    }

    logger("logconsumer", "started...");

    const rmq_env env = new_rmq_env();

    conn = rmq_connect(env);

    queuename = rmq_queue_declare(conn, env.queue);

    rmq_consume();

    rmq_close(conn, queuename);

    return EXIT_SUCCESS;
}

void rmq_consume() {
    size_t msg_len = 14+queuename.len;
    char* msg = malloc(msg_len * sizeof(char));

    snprintf(msg, msg_len, "consuming on %s\n", (const char *) queuename.bytes);
    logger("rmq_consume", msg);
    free(msg);

    amqp_basic_consume(conn, 1, queuename, amqp_empty_bytes, 0, 1, 0,
                       amqp_empty_table);
    const amqp_rpc_reply_t cns_reply = amqp_get_rpc_reply(conn);
    if (!rmq_check_rpc_reply(&cns_reply)) {
        perror("error in basic consume");
        exit(EXIT_FAILURE);
    }

    amqp_frame_t frame;

    for (;;) {
        amqp_rpc_reply_t ret;
        amqp_envelope_t envelope;

        amqp_maybe_release_buffers(conn);

        ret = amqp_consume_message(conn, &envelope, NULL, 0);
        if (!rmq_check_rpc_reply(&ret)) {
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
            cJSON* data = cJSON_ParseWithLength(body.bytes, body.len);

            logger("rmq_consume: recv", data->string);

            amqp_destroy_envelope(&envelope);
            cJSON_free(data);
        }
    }
}

void sig_handler(int sig) {
    /**
     * NB: can only use "async" safe calls here.
     * write instead of printf, for example.
     * See https://beej.us/guide/bgipc/html/#signals
     */
    switch (sig) {
        case SIGINT:
        case SIGHUP:
        case SIGTERM:
        case SIGQUIT:
            const char msg[] = "signal handled\n";
            write(0, msg, sizeof(msg));
            rmq_close(conn, queuename);
            exit(EXIT_SUCCESS);
        default:
            const char errmsg[] = "unknown signal handled\n";
            write(0, errmsg, sizeof(errmsg));
            rmq_close(conn, queuename);
            exit(EXIT_FAILURE);
    }
}
