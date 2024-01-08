const std = @import("std");
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});
const sysmsg = @cImport({
    @cInclude("sys/msg.h");
});
const assert = std.debug.assert;
const errno = std.os.errno;

/// `MessageQueue` is a System V message queue wrapper.
/// The calling process must have write permission on the message queue
/// in order to send a message, and read permission to receive a message.
pub fn MessageQueue(comptime T: type) type {
    return struct {
        msgsize: usize,
        msqid: c_int,
        msqproj: c_int,
        msqtype: c_long,

        const Self = @This();

        const MessageQueueError = error {
            EOQ, // queue has been closed
            ReadError,
            WriteError,
        };

        const Message = struct {
            mtype: c_long,
            mdata: T,
        };

        /// Creates a `MessageQueue` with msqid derived from the given file path.
        pub fn init(path: [*c]const u8) MessageQueueError!Self {
            const msqproj = 1;
            const key = sysmsg.ftok(path, msqproj);
            if (key == -1) {
                c.perror("unable to create msqid");
                return MessageQueueError.ReadError;
            }
            const msqid = sysmsg.msgget(key, 0o666 | sysmsg.IPC_CREAT);
            if (msqid == -1) {
                c.perror("unable to get message queue");
                return MessageQueueError.WriteError;
            }
            return .{
                .msgsize = @sizeOf(T),
                .msqid = msqid,
                .msqproj = msqproj,
                .msqtype = 1,
            };
        }

        /// Remove the message queue
        pub fn deinit(self: Self) void {
            if(sysmsg.msgctl(self.msqid, sysmsg.IPC_RMID, null) == -1) {
                c.perror("unable to destroy message queue");
            }
        }

        /// Publishes a new element to the back of the queue.
        pub fn publish(self: Self, v: T) MessageQueueError!void {
            var mesg = Message{.mtype = self.msqtype, .mdata = v};
            if (sysmsg.msgsnd(self.msqid, &mesg, self.msgsize, 0) == -1) {
                c.perror("unable to send message");
                return MessageQueueError.WriteError;
            }
        }

        /// Consumes the next element from the queue and returns it.
        pub fn consume(self: Self) MessageQueueError!T {
            var buf: Message = undefined;
            if (sysmsg.msgrcv(self.msqid, &buf, self.msgsize, self.msqtype, 0) == -1) {
                // TODO: check for EIDRM and return `MessageQueueError.EOQ`
                c.perror("unable to receive message");
                return MessageQueueError.ReadError;
            }
            return buf.mdata;
        }
    };
}

test MessageQueue {
    const testing = std.testing;
    const Elem = struct {
        data: usize,
        const Self = @This();
    };

    const q = try MessageQueue(Elem).init("./internal/ipc/queue.zig");
    defer q.deinit();

    // Elems
    var elems: [2]Elem = .{.{.data = 1}, .{.data = 2}};

    // One
    try q.publish(elems[0]);
    var elem = try q.consume();
    try testing.expect(elem.data == elems[0].data);

    // Two
    try q.publish(elems[0]);
    try q.publish(elems[1]);
    elem = try q.consume();
    try testing.expect(elem.data == elems[0].data);
    elem = try q.consume();
    try testing.expect(elem.data == elems[1].data);

    // Interleaved
    try q.publish(elems[0]);
    elem = try q.consume();
    try testing.expect(elem.data == elems[0].data);
    try q.publish(elems[1]);
    elem = try q.consume();
    try testing.expect(elem.data == elems[1].data);
}


