const std = @import("std");
const MessageQueue = @import("msgqueue").MessageQueue;

const Child = std.process.Child;

const HeartBeat = struct {
    status: []const u8,
};

pub fn main() !void {
    var mailbox = try MessageQueue(HeartBeat).init(".");
    
    Child.init(argv: []const []const u8, allocator: mem.Allocator)

    const pid = try std.os.fork();
    switch (pid) {
        0 => { // producer
            std.debug.print("child sending heartbeat\n", .{});
            const hb = HeartBeat{.status = "ok"};
            const writer = mailbox.publisher();
            try writer.publish(hb);
            try writer.publish(hb);
            try writer.publish(hb);
            try writer.publish(hb);
            try writer.done();
        },
        else => { // consumer
            defer mailbox.deinit();
            std.debug.print("parent waiting for heartbeats\n", .{});
            const reader = mailbox.subscribe();
            while (reader.next()) |data| {
                std.debug.print("{s}\n", .{data.status});
            }
            const result = std.os.waitpid(pid, 0);
            std.debug.print("child with pid {d} finished\n", .{result.pid});
        }
    }
}
