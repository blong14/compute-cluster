const MessageQueue = @import("./ipc/msgqueue.zig").MessageQueue;

pub fn mailbox(path: []const u8) !MessageQueue {
    return try MessageQueue.init(path);
}
