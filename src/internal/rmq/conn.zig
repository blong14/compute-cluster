const std = @import("std");
const rmq = @cImport({
    @cInclude("amqp.h");
    @cInclude("amqp_tcp_socket.h");
});
const Allocator = std.mem.Allocator;

pub const Env = struct {
    hostname: [*c]const u8,
    port: c_int,
    username: [*c]const u8,
    password: [*c]const u8,
    queuename: [*c]const u8,

    const Self = @This();

    pub fn init() !Self {
        const p = std.os.getenv("RMQ_PORT") orelse "5672";
        const port = try std.fmt.parseInt(comptime c_int, p, 10);
        return .{
            .hostname = std.os.getenv("RMQ_HOST") orelse "localhost",
            .port = port,
            .username = std.os.getenv("RMQ_USER") orelse "guest",
            .password = std.os.getenv("RMQ_PASSWORD") orelse "guest",
            .queuename = std.os.getenv("RMQ_QUEUE") orelse "log",
        };
    }
};

pub const Error = error {
   OutOfMemory,
   UnableToDeclareQueue,
   UnableToLogIn,
   UnableToConnect,
   UnableToOpenSocket,
   UnableToOpenChannel,
};

pub const Response = enum(u8) {
    Normal,
    ServerException,
    LibraryException,
    UnknownError,
};

pub const Conn = struct {
    conn: rmq.amqp_connection_state_t,

    const Self = @This();

    pub fn connect(env: Env) Error!Self {
        const conn: rmq.amqp_connection_state_t = rmq.amqp_new_connection() orelse return Error.UnableToConnect;
        const socket: ?*rmq.amqp_socket_t = rmq.amqp_tcp_socket_new(conn) orelse return Error.UnableToConnect;
        const status: isize = rmq.amqp_socket_open(socket, env.hostname, env.port);
        if (status != 0) {
            return Error.UnableToOpenSocket;
        }
        var log_in_reply: rmq.amqp_rpc_reply_t = rmq.amqp_login(
            conn, "/", 0, rmq.AMQP_DEFAULT_FRAME_SIZE, 0, rmq.AMQP_SASL_METHOD_PLAIN, env.username, env.password);
        if(check_rpc_reply(&log_in_reply) != Response.Normal) {
            return Error.UnableToLogIn;
        }
        _ = rmq.amqp_channel_open(conn, 1);
        var open_reply: rmq.amqp_rpc_reply_t = rmq.amqp_get_rpc_reply(conn);
        if (check_rpc_reply(&open_reply) != Response.Normal) {
            return Error.UnableToOpenChannel;
        }
        return .{ .conn = conn };
    }

    pub fn close(self: Self) void {
        _ = rmq.amqp_channel_close(self.conn, 1, rmq.AMQP_REPLY_SUCCESS);
        _ = rmq.amqp_connection_close(self.conn, rmq.AMQP_REPLY_SUCCESS);
        _ = rmq.amqp_destroy_connection(self.conn);
    }

    pub fn consume(self: Self, alloc: Allocator, comptime T: type, comptime callback: (fn(msg: *T) void)) !void {
        var envelope: rmq.amqp_envelope_t = undefined;
        defer _ = rmq.amqp_destroy_envelope(&envelope);
        while (true) {
            var retm = rmq.amqp_consume_message(self.conn, &envelope, null, 0);
            if (rmq.AMQP_RESPONSE_NORMAL != retm.reply_type) {
                break;
            }
            const body: rmq.amqp_bytes_t = envelope.message.body;
            var json: []const u8 = @as(
                [*]u8,
                @ptrCast(body.bytes.?),
            )[0..body.len];
            const message = try std.json.parseFromSlice(*T, alloc, json, .{});
            callback(message.value);
            message.deinit();
        }
    }

    pub fn queue_declare(self: Self, queue: [*c]const u8) Error!Response {
        const queue_declare_ok: *rmq.amqp_queue_declare_ok_t = rmq.amqp_queue_declare(
            self.conn, 1, rmq.amqp_cstring_bytes(queue), 0, 0, 0, 1, rmq.amqp_empty_table);
        var reply: rmq.amqp_rpc_reply_t = rmq.amqp_get_rpc_reply(self.conn);
        if (check_rpc_reply(&reply) != Response.Normal) {
            return Error.UnableToDeclareQueue;
        }
        const queuename: rmq.amqp_bytes_t = rmq.amqp_bytes_malloc_dup(queue_declare_ok.*.queue);
        if (queuename.bytes == rmq.NULL) {
            return Error.OutOfMemory;
        }
        var str: []const u8 = @as(
            [*]u8,
            @ptrCast(queuename.bytes.?),
        )[0..queuename.len];
        std.debug.print("queue {s} declared\n", .{str});
        return Response.Normal;
    }
};

fn check_rpc_reply(reply: *rmq.amqp_rpc_reply_t) Response {
    switch (reply.*.reply_type) {
        rmq.AMQP_RESPONSE_NORMAL => return Response.Normal,
        rmq.AMQP_RESPONSE_SERVER_EXCEPTION => return Response.ServerException,
        rmq.AMQP_RESPONSE_LIBRARY_EXCEPTION => return Response.LibraryException,
        else => return Response.UnknownError,
    }
}
