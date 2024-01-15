const std = @import("std");
const sig = std.os.SIG;

const rmq = @import("rmq");
const RMQConn = rmq.Conn;
const RMQEnv = rmq.Env;
const RMQError = rmq.Error;
const RMQResponse = rmq.Response;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Message = struct {
    action: []const u8,
    msg: []const u8,
};

fn on_message(msg: *const Message) void {
    std.debug.print("msg recv {s}", .{msg.*.msg});
}

var SigHandler = struct {
    conn: ?RMQConn,

    const Self = @This();

    fn init() Self {
        return .{.conn = null};
    }

    fn set_conn(self: *Self, c: RMQConn) void {
        self.*.conn = c;
    }

    fn handle(self: Self) !void {
        if (self.conn) |conn| {
            conn.close();
        }
    }
}.init();

fn sig_handler(signal: c_int) callconv(.C) void {
    switch (signal) {
        sig.HUP, sig.INT, sig.QUIT, sig.TERM => {
            _ = std.os.write(0, "signal handled\n") catch |err| {
                std.debug.print("Oops! {s}", .{@errorName(err)});
            };
            SigHandler.handle() catch |err| {
                std.debug.print("Oops! {s}", .{@errorName(err)});
            };
            std.os.exit(0);
        },
        else => {
            _ = std.os.write(0, "unknown signal handled\n") catch |err| {
                std.debug.print("Oops! {s}", .{@errorName(err)});
            };
            SigHandler.handle() catch |err| {
                std.debug.print("Oops! {s}", .{@errorName(err)});
            };
            std.os.exit(1);
        }
    }
}

pub fn main() !void {
    std.debug.print("zlogconsumer started...\n", .{});
    const env = try RMQEnv.init();
    const conn = try RMQConn.connect(env);
    defer conn.close();
    const resp = try conn.queue_declare(env.queuename);
    if (RMQResponse.Normal != resp) {
        std.debug.print("queue not declared", .{});
        std.os.exit(1);
    }
    const pid = try std.os.fork();
    switch (pid) {
        0 => {
            std.debug.print("child waiting for incoming messages\n", .{});
            SigHandler.set_conn(conn);
            const sigaction = &std.os.Sigaction{
                .handler = .{ .handler = sig_handler },
                .mask = std.os.empty_sigset,
                .flags = 0,
            };
            try std.os.sigaction(sig.HUP, sigaction, null);
            try std.os.sigaction(sig.INT, sigaction, null);
            try std.os.sigaction(sig.TERM, sigaction, null);
            try std.os.sigaction(sig.QUIT, sigaction, null);
            try conn.consume(allocator, Message, on_message);
        },
        else => {
            std.debug.print("parent waiting for child to finish\n", .{});
            const result = std.os.waitpid(pid, 0);
            std.debug.print("child with pid {d} finished\n", .{result.pid});
        }
    }
}
