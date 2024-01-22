const std = @import("std");
const c = @cImport({
    @cInclude("errno.h");
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});
const sys = @cImport({
    @cInclude("sys/ipc.h");
    @cInclude("sys/msg.h");
    @cInclude("sys/types.h");
});

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

        const EOQ = 2;

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
        const ReadIter = struct {
            msqid: c_int,
            msgsize: usize,

            /// Consumes the next element from the queue and returns it.
            /// returns null when done reading.
            pub fn next(self: ReadIter) ?T {
                var buf: Message = undefined;
                switch (errno(sys.msgrcv(self.msqid, &buf, self.msgsize, 0, 0))) {
                    .SUCCESS => {
                        if (buf.mtype == EOQ) {
                            return null;
                        }
                        return buf.mdata;
                    },
                    else => {
                        c.perror("unable to read message");
                        return null;
                    }
                }
            }
        };

        /// Subscribe to receive messages from this message queue.
        pub fn subscribe(self: Self) ReadIter {
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
                switch (errno(sys.msgsnd(self.msqid, &mesg, self.msgsize, 0))) {
                    .SUCCESS => return,
                    .IDRM => return MessageQueueError.EOQ,
                    else => {
                        c.perror("unable to send message");
                        return MessageQueueError.WriteError;
                    }
                }
            }

            pub fn done(self: Writer) MessageQueueError!void {
                var end: Message = .{.mtype = EOQ, .mdata = undefined};
                switch (errno(sys.msgsnd(self.msqid, &end, self.msgsize, 0))) {
                    .SUCCESS => return,
                    .IDRM => return MessageQueueError.EOQ,
                    else => {
                        c.perror("unable to send message");
                        return MessageQueueError.WriteError;
                    }
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

    const elem: Elem = .{.data = 1};

    // Create a mailbox to read and write messages to.
    // The main thread will be in charge of cleaning up the mailbox
    var mailbox = try MessageQueue(Elem).init(".");
    defer mailbox.deinit();

    const reader = mailbox.subscribe();
    const writer = try std.Thread.spawn(.{}, struct {
        pub fn publish(outbox: MessageQueue(Elem).Writer, data: Elem) !void {
            try outbox.publish(data);
        }
    }.publish, .{mailbox.publisher(), elem});

    const actual = reader.next();
    try testing.expect(actual.?.data == elem.data);
    writer.join();
}

test "Test count" {
    const testing = std.testing;
    const Elem = struct {
        data: usize,
        const Self = @This();
    };

    var elems = [_]Elem {.{.data = 1}, .{.data = 2}};

    // Create a mailbox to read and write messages to.
    // The main thread will be in charge of cleaning up the mailbox
    var mailbox = try MessageQueue(Elem).init(".");
    defer mailbox.deinit();

    // Count all messages
    const reader = mailbox.subscribe();
    const writer = try std.Thread.spawn(.{}, struct {
        pub fn publish(outbox: MessageQueue(Elem).Writer, data: []Elem) !void {
            defer outbox.done() catch |err| {
                std.debug.print("Oops {s}\n", .{@errorName(err)});
            };
            for (data) |elem| {
                try outbox.publish(elem);
            }
        }
    }.publish, .{mailbox.publisher(), &elems});

    var count: u8 = 0;
    while (reader.next()) |_| {
        count += 1;
    }
    try testing.expect(count == elems.len);
    writer.join();
}

test "Pool" {
    const testing = std.testing;
    const Timer = std.time.Timer;
    const ThreadPool = std.Thread.Pool;
    const WaitGroup = std.Thread.WaitGroup;
    const Elem = struct {
       data: usize,
       const Self = @This();
    };

    var elems = [_]Elem {.{.data = 1}, .{.data = 2}};
    var gpa = testing.allocator;
    var wait_group: WaitGroup = .{};
    var thread_pool: ThreadPool = undefined;
    try thread_pool.init(.{ .allocator = gpa });
    defer thread_pool.deinit();

    // Create a mailbox to read and write messages to.
    // The main thread will be in charge of cleaning up the mailbox
    var mailbox = try MessageQueue(Elem).init(".");

    var timer = try Timer.start();

    for (0..1_000_000) |_| {
        wait_group.start();
        try thread_pool.spawn(struct {
            pub fn publish(wg: *WaitGroup, outbox: MessageQueue(Elem).Writer, data: []Elem) void {
                defer wg.finish();
                for (data) |elem| {
                    outbox.publish(elem) catch |err| {
                        std.debug.print("Ooops {s}\n", .{@errorName(err)});
                        return;
                    };
                }
            }
        }.publish, .{&wait_group, mailbox.publisher(), &elems});
    }

    const reader = try std.Thread.spawn(.{}, struct {
        pub fn consume(inbox: MessageQueue(Elem).ReadIter) void {
            var tmr = Timer.start() catch return;
            var count: f64 = 0;
            while (inbox.next()) |_| {
                count += 1;
            }
            const elapsed: f64 = @floatFromInt(tmr.read());
            const in = elapsed / std.time.ns_per_ms;
            const per: f64 = count / (in / std.time.ms_per_s);
            std.debug.print(
                "count {d} in {d:.2}ms {d:.2}/sec\n", .{count, in, per});
        }
    }.consume, .{mailbox.subscribe()});

    thread_pool.waitAndWork(&wait_group);
    const stop = mailbox.publisher();
    try stop.done();
    reader.join();
    mailbox.deinit();

    const end: f64 = @floatFromInt(timer.read());
    std.debug.print("finished in {d:.2}ms\n", .{(end/std.time.ns_per_ms)});
    std.time.sleep(100_000);
}
