#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "amqp.h"
#include "amqp_tcp_socket.h"

bool check_reply(amqp_rpc_reply_t);
void consume(amqp_connection_state_t);

int main(void)
{
	amqp_socket_t *socket = NULL;
	amqp_bytes_t queuename;
	const char *host, *port, *user, *password, *queue;

	if ((host = getenv("RMQ_HOST")) == NULL)
		host = "localhost";

	if ((port = getenv("RMQ_PORT")) == NULL)
		port = "5672";

	if ((user = getenv("RMQ_USER")) == NULL) {
		user = "guest";
	}

	if ((password = getenv("RMQ_PASSWORD")) == NULL) {
		password = "guest";
	}

	if ((queue = getenv("RMQ_QUEUE")) == NULL) {
		queue = "log";
	}

	const amqp_connection_state_t conn = amqp_new_connection();
	socket = amqp_tcp_socket_new(conn);
	if (!socket) {
		perror("error creating TCP socket");
		exit(EXIT_FAILURE);
	}

	printf("opening socket @ amqp://%s:%s\n", host, port);
	int status = amqp_socket_open(socket, host, atoi(port));
	if (AMQP_STATUS_OK != status) {
		perror("error opening TCP socket");
		exit(status);
	}

	amqp_rpc_reply_t r = amqp_login(
		conn, "/", 0, AMQP_DEFAULT_FRAME_SIZE, 0, AMQP_SASL_METHOD_PLAIN, user, password);
	if (!check_reply(r)) {
		perror("error logging in");
		exit(EXIT_FAILURE);
	}

	amqp_channel_open(conn, 1);
	if (!check_reply(amqp_get_rpc_reply(conn))) {
		perror("error opening channel");
		exit(EXIT_FAILURE);
	}

	const amqp_queue_declare_ok_t *queue_declare_ok =  amqp_queue_declare(
		conn, 1, amqp_cstring_bytes(queue), 0, 0, 0, 1, amqp_empty_table);
	if (!check_reply(amqp_get_rpc_reply(conn))) {
		perror("error declaring queue");
		exit(EXIT_FAILURE);
	}

	queuename = amqp_bytes_malloc_dup(queue_declare_ok->queue);
	if (queuename.bytes == NULL) {
		perror("out of memory while copying queue name");
		exit(EXIT_FAILURE);
	}

	amqp_basic_consume(conn, 1, queuename, amqp_empty_bytes, 0, 1, 0,
					   amqp_empty_table);
	if (!check_reply(amqp_get_rpc_reply(conn))) {
		perror("error in basic consume");
		exit(EXIT_FAILURE);
	}

	fprintf(stdout, "consuming on %s\n", (const char *)queuename.bytes);
	consume(conn);

	amqp_bytes_free(queuename);
	amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS);
	amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
	amqp_destroy_connection(conn);

	return EXIT_SUCCESS;
}

bool check_reply(amqp_rpc_reply_t reply)
{
	switch (reply.reply_type) {
		case AMQP_RESPONSE_NORMAL:
			return true;
		case AMQP_RESPONSE_SERVER_EXCEPTION:
			fprintf(stderr, "AMQP server exception\n");
			return false;
		case AMQP_RESPONSE_LIBRARY_EXCEPTION:
			fprintf(stderr, "AMQP library exception\n");
			return false;
		default:
			return false;
	}
}

void consume(amqp_connection_state_t conn)
{
	amqp_frame_t frame;

	for (;;) {
		amqp_rpc_reply_t ret;
		amqp_envelope_t envelope;

		amqp_maybe_release_buffers(conn);

		ret = amqp_consume_message(conn, &envelope, NULL, 0);
		if (!check_reply(ret)) {
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
			if(!amqp_basic_ack(conn, envelope.channel, envelope.delivery_tag, 0)) {
				fprintf(stderr, "basic ack failed %s\n", (const char *)body.bytes);
				puts("basic ack failed");
			}
			fprintf(stdout, "message received %s", (const char *)body.bytes);
			amqp_destroy_envelope(&envelope);
		}
	}
}
