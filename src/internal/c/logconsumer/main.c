#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "amqp.h"
#include "amqp_tcp_socket.h"

#define PORT 5672
#define QUEUE "log"
// #define EXCHANGE "amq.direct"
// #define BINDINGKEY "news-summary"

bool check_reply(amqp_rpc_reply_t);
void consume(amqp_connection_state_t);

int main(void)
{
	amqp_socket_t *socket = NULL;
	amqp_bytes_t queuename;

	const amqp_connection_state_t conn = amqp_new_connection();
	socket = amqp_tcp_socket_new(conn);
	if (!socket) {
		perror("error creating TCP socket");
		exit(EXIT_FAILURE);
	}

	const char *host = getenv("RMQ_HOST");
	if (host == NULL) host = "localhost";

	int status = amqp_socket_open(socket, host, PORT);
	if (AMQP_STATUS_OK != status) {
		perror("error opening TCP socket");
		exit(status);
	}

	const char *user = getenv("RMQ_USER");
	if (user == NULL) user = "guest";

	const char *password = getenv("RMQ_PASSWORD");
	if (password == NULL) password = "guest";

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
		conn, 1, amqp_cstring_bytes(QUEUE), 0, 0, 0, 1, amqp_empty_table);
	if (!check_reply(amqp_get_rpc_reply(conn))) {
		perror("error declaring queue");
		exit(EXIT_FAILURE);
	}

	queuename = amqp_bytes_malloc_dup(queue_declare_ok->queue);
	if (queuename.bytes == NULL) {
		perror("out of memory while copying queue name");
		exit(EXIT_FAILURE);
	}

	// amqp_queue_bind(conn, 1, queuename, amqp_cstring_bytes(EXCHANGE),
	// 				amqp_cstring_bytes(BINDINGKEY), amqp_empty_table);
	// if (!check_reply(amqp_get_rpc_reply(conn))) {
	// 	fprintf(stderr, "error binding to queue");
	// 	perror("error binding to queue");
	// 	exit(EXIT_FAILURE);
	// }

	amqp_basic_consume(conn, 1, queuename, amqp_empty_bytes, 0, 1, 0,
					   amqp_empty_table);
	if (!check_reply(amqp_get_rpc_reply(conn))) {
		perror("error in basic consume");
		exit(EXIT_FAILURE);
	}

	puts("rmq client connected...");
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
	puts("consuming...");

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
						case AMQP_BASIC_ACK_METHOD:
							/* if we've turned publisher confirms on, and we've published a
							 * message here is a message being confirmed.
							 */
							break;
						case AMQP_BASIC_RETURN_METHOD:
							/* if a published message couldn't be routed and the mandatory
							 * flag was set this is what would be returned. The message then
							 * needs to be read.
							 */
							{
								amqp_message_t message;
								if (!check_reply(amqp_read_message(conn, frame.channel, &message, 0))) {
									return;
								}
								amqp_destroy_message(&message);
							}
							break;
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
			if(!amqp_basic_ack(conn, 1, 0, 0)) {
				puts("basic ack failed");
			}
			amqp_bytes_t body = envelope.message.body;
			printf("received message with length %lu", body.len);
			printf("message %s", (const char *)body.bytes);
			amqp_destroy_envelope(&envelope);
		}
	}
}
