const std = @import("std");
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});
const sys = @cImport({
    @cInclude("sys/msg.h");
});
const errno = std.os.errno;

/// `MessageQueue` is a System V message queue wrapper.
/// The calling process must have write permission on the message queue
/// in order to send a message, and read permission to receive a message.
pub fn MessageQueue(comptime T: type) type {
    return struct {
        eoq: c_int,
        msgsize: usize,
        msqid: c_int,
        msqproj: c_int,
        msqtype: c_long,

        const Self = @This();

        const EOQ = 2;

        const MessageQueueError = error {
            EOQ, // queue has been closed
            ReadError,
            WriteError,
        };

        const Message = struct {
            mtype: c_long,
            mdata: T,
        };

        const Done = struct {
            mtype: c_long,
            mdata: c_int,
        };

        /// Creates a `MessageQueue` with msqid derived from the given file path.
        pub fn init(path: [*c]const u8) MessageQueueError!Self {
            const msqproj = 1;
            const key = sys.ftok(path, msqproj);
            if (key == -1) {
                c.perror("unable to create msqid");
                return MessageQueueError.ReadError;
            }
            const msqid = sys.msgget(key, 0o666 | sys.IPC_CREAT);
            if (msqid == -1) {
                c.perror("unable to get message queue");
                return MessageQueueError.WriteError;
            }
            return .{
                .eoq = 2,
                .msgsize = @sizeOf(T),
                .msqid = msqid,
                .msqproj = msqproj,
                .msqtype = 1,
            };
        }

        /// Remove the message queue
        pub fn deinit(self: *Self) void {
            if(sys.msgctl(self.*.msqid, sys.IPC_RMID, null) == -1) {
                c.perror("unable to destroy message queue");
            }
            self.* = undefined;
        }

        /// Reader consumes messages off the queue.
        /// The reader is active until there is an error
        /// or the `Done` message is consumed.
        const Reader = struct {
            msqid: c_int,
            msgsize: usize,

            /// Consumes the next element from the queue and returns it.
            pub fn consume(self: Reader) MessageQueueError!T {
                var buf: Message = undefined;
                if (sys.msgrcv(self.msqid, &buf, self.msgsize, 0, 0) == -1) {
                    // TODO: check for EIDRM and return `MessageQueueError.EOQ`
                    c.perror("unable to receive message");
                    return MessageQueueError.ReadError;
                }
                if (buf.mtype == EOQ) {
                    return MessageQueueError.EOQ;
                }
                return buf.mdata;
            }
        };

        /// Subscribe to receive messages from this message queue.
        pub fn subscriber(self: Self) Reader {
            return .{
                .msqid = self.msqid,
                .msgsize = self.msgsize,
            };
        }

        /// Writer publishes messages to the queue.
        /// The writer must call `done` to signal
        /// that the subscriber should stop consuming messages.
        const Writer = struct {
            msqid: c_int,
            msgsize: usize,
            msqtype: c_long,

            /// Publishes a new element to the back of the queue.
            pub fn publish(self: Writer, v: T) MessageQueueError!void {
                var mesg = Message{.mtype = self.msqtype, .mdata = v};
                if (sys.msgsnd(self.msqid, &mesg, self.msgsize, 0) == -1) {
                    c.perror("unable to send message");
                    return MessageQueueError.WriteError;
                }
            }

            /// Signal to any subscribers that this message queue has finished
            /// sending messages.
            pub fn done(self: Writer) MessageQueueError!void {
                const eoq = Done{.mtype = 2, .mdata = 0};
                if (sys.msgsnd(self.msqid, &eoq, @sizeOf(c_int), 0) == -1) {
                    c.perror("unable to send message");
                    return MessageQueueError.WriteError;
                }
            }
        };

        /// Create a publisher to send messages on the queue.
        pub fn publisher(self: Self) Writer {
            return .{
                .msqid = self.msqid,
                .msgsize = self.msgsize,
                .msqtype = self.msqtype,
            };
        }
    };
}

test MessageQueue {
    const testing = std.testing;
    const Elem = struct {
        data: usize,
        const Self = @This();
    };
    var elems = [_]Elem {.{.data = 1}, .{.data = 2}};
    const msgq_name = ".";

    // Create a mailbox to read and write messages to.
    // The main thread will be in charge of cleaning up the mailbox
    var mailbox = try MessageQueue(Elem).init(msgq_name);
    defer mailbox.deinit();

    // One
    var writer = try std.Thread.spawn(.{}, struct {
        pub fn write(outbox: MessageQueue(Elem).Writer, data: Elem) !void {
            try outbox.publish(data);
            try outbox.done();
        }
    }.write, .{mailbox.publisher(), elems[0]});

    var reader = mailbox.subscriber();

    var actual: Elem = undefined;
    while (true) {
        actual = reader.consume() catch |err| switch (err) {
            error.EOQ => break,
            else => unreachable,
        };
    }
    try testing.expect(actual.data == elems[0].data);
    writer.join();

    // Count all messages
    writer = try std.Thread.spawn(.{}, struct {
        pub fn write(outbox: MessageQueue(Elem).Writer, data: []Elem) !void {
            defer outbox.done() catch |err| {
                std.debug.print("{s}\n", .{@errorName(err)});
            };
            for (data) |elem| {
                try outbox.publish(elem);
            }
        }
    }.write, .{mailbox.publisher(), &elems});

    var count: u8 = 0;
    while (true) {
        _ = reader.consume() catch |err| switch (err) {
            error.EOQ => break,
            else => unreachable,
        };
        count += 1;
    }
    try testing.expect(count == elems.len);
    writer.join();
}


