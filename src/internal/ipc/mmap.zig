const std = @import("std");
const c = @cImport({
    @cInclude("stdio.h");
});
const fcntl = @cImport({
    @cInclude("fcntl.h");
});

const errno = std.os.errno;
const FixedBuffer = std.io.FixedBufferStream;

pub fn MMap(comptime T: type) type {
    return struct {
        buf: FixedBuffer([]align(std.mem.page_size) u8),

        const Self = @This();

        const Error = error{
            ReadError,
            WriteError,
        } || std.os.OpenError || std.os.MMapError;

        pub fn init(path: []const u8) Error!Self {
            const fd = try std.os.open(
                path,
                fcntl.O_RDWR,
                0o666,
            );
            if (fd == -1) {
                return Error.ReadError;
            }
            var sbuf: std.os.Stat = undefined;
            if (std.c.fstat(fd, &sbuf) == -1) {
                c.perror("stat");
                return Error.ReadError;
            }
            const data = try std.os.mmap(
                null,
                @sizeOf(T) * 8,
                std.os.PROT.READ | std.os.PROT.WRITE,
                std.os.MAP.SHARED,
                fd,
                0,
            );
            return .{
                .buf = std.io.fixedBufferStream(data),
            };
        }

        pub fn append(self: *Self, value: *const T) Error!void {
            var writer = self.buf.writer();
            try writer.writeStruct(value.*);
        }

        pub fn read(self: *Self, idx: usize) !T {
            try self.buf.seekTo(@sizeOf(T) * idx);
            const reader = self.buf.reader();
            return try reader.readStruct(T);
        }

        const ReadIter = struct {
            current: usize,
            len: usize,
            stream: FixedBuffer([]align(std.mem.page_size) u8),

            pub fn next(self: *ReadIter) !?T {
                // [0, 1, 2, 3, 4, 5, 6, 7]
                // [x, x,  ,  ,  ,  ,  ,  ]
                if (self.current >= self.len) {
                    return null;
                }
                try self.stream.seekTo(@sizeOf(T) * self.current);
                const reader = self.stream.reader();
                self.current += 1;
                return try reader.readStruct(T);
            }
        };

        pub fn readIter(self: *Self) ReadIter {
            return .{
                .current = 0,
                .len = 2,
                .stream = self.buf,
            };
        }
    };
}

test MMap {
    // const testing = std.testing;
    const Entity = extern struct {
        key: [*c]const u8,
    };

    // const expected: Entity = .{.key = "hello"};
    const entities: [2]Entity = .{ .{ .key = "key1" }, .{ .key = "key2" } };

    var map = try MMap(Entity).init("tmp/out.dat");
    for (entities) |entity| {
        try map.append(&entity);
    }

    var reader = map.readIter();
    while (reader.next() catch null) |entity| {
        std.debug.print("actual {s}\n", .{entity.key});
    }
    // try testing.expect(std.mem.eql(u8, expected.key, actual.key));
}
