const std = @import("std");

const MessageQueue = @import("queue").MessageQueue;

const HeartBeat = struct {
    status: []const u8,
};

pub fn main() !void {
    const q = try MessageQueue(HeartBeat).init(".");

    const pid = try std.os.fork();
    switch (pid) {
        0 => { // producer
            std.debug.print("child sending heartbeat\n", .{});
            defer q.deinit();
            const hb = HeartBeat{.status = "ok"};
            try q.publish(hb);
            try q.publish(hb);
            try q.publish(hb);
            try q.publish(hb);
        },
        else => { // consumer
            std.debug.print("parent waiting for heartbeats\n", .{});
            while (true) {
                var data: HeartBeat = try q.consume();
                std.debug.print("{s}\n", .{data.status});
            }
            const result = std.os.waitpid(pid, 0);
            std.debug.print("child with pid {d} finished\n", .{result.pid});
        }
    }
}