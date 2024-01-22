const std = @import("std");

const File = std.fs.File;
const FixedBuffer = std.io.FixedBufferStream;

const copyForwards = std.mem.copyForwards;

pub fn MMap(comptime T: type) type {
    return struct {
        buf: FixedBuffer([]align(std.mem.page_size) u8),
        count: usize,
        file: File,
        len: usize,
        size: usize,

        const Self = @This();

        pub const Error = error {
            EndOfStream,
            ReadError,
            PipeBusy,
            SharingViolation,
            WriteError,
        } || std.os.OpenError || std.os.WriteError || std.os.MMapError;

        pub fn init(path: []const u8, capacity: usize) Error!Self {
            const file = try std.fs.cwd().createFile(path, .{
                .read = true,
                .truncate = false,
            });
            try file.setEndPos(capacity);
            var data = try std.os.mmap(
                null,
                capacity,
                std.os.PROT.READ | std.os.PROT.WRITE,
                std.os.MAP.SHARED,
                file.handle,
                0,
            );
            return .{
                .buf = std.io.fixedBufferStream(data),
                .count = 0,
                .file = file,
                .len = capacity / @sizeOf(T),
                .size = @sizeOf(T),
            };
        }

        pub fn deinit(self: *Self) void {
            std.os.munmap(self.buf.buffer);
            self.file.close();
            self.* = undefined;
        }

        pub fn append(self: *Self, value: T) Error!void {
            if (self.count == self.len) return Error.WriteError;
            try self.buf.seekTo(self.size * self.count);
            try self.buf.writer().writeStruct(value);
            self.count += 1;
        }

        pub fn insert(self: *Self, idx: usize, value: T) Error!void {
            if (self.count == self.len) return Error.WriteError;
            const index: usize = self.size * idx;
            try self.buf.seekTo(index);
            const start: usize = try self.buf.getPos();
            const end: usize =  try self.buf.getEndPos() - self.size;
            copyForwards(u8, self.buf.buffer[start + self.size..], self.buf.buffer[start..end]);
            try self.buf.writer().writeStruct(value);
            self.count += 1;
        }

        pub fn update(self: *Self, idx: usize, value: T) Error!void {
            const index: usize = self.size * idx;
            if (index >= self.len) return Error.WriteError;
            try self.buf.seekTo(index);
            try self.buf.writer().writeStruct(value);
        }

        pub fn read(self: *Self, idx: usize) Error!T {
            const index: usize = self.size * idx;
            if (index >= self.len) return Error.ReadError;
            try self.buf.seekTo(index);
            return try self.buf.reader().readStruct(T);
        }
    };
}

test "MMap append" {
    const testing = std.testing;
    const Row = extern struct {
        key: u64,
        value: [*c]const u8,
    };

    var alloc = testing.allocator;
    const testDir = testing.tmpDir(.{});
    const pathname = try testDir.dir.realpathAlloc(alloc, ".");
    defer alloc.free(pathname);
    defer testDir.dir.deleteDir(pathname) catch {};

    // given
    const key = std.hash.Murmur2_64.hash("__key__");
    const expected: Row = .{.key = key, .value = "__value__"};
    const filename = try std.fmt.allocPrint(alloc, "{s}/{s}", .{pathname, "append.dat"});
    defer alloc.free(filename);

    var map = try MMap(Row).init(filename, std.mem.page_size);
    defer map.deinit();

    // when
    try map.append(Row{.key = std.hash.Murmur2_64.hash("__key_0__"), .value = "__value0__"});
    try map.append(Row{.key = std.hash.Murmur2_64.hash("__key_1__"), .value = "__value1__"});
    try map.append(Row{.key = std.hash.Murmur2_64.hash("__key_2__"), .value = "__value2__"});
    try map.append(expected);

    // then
    try testing.expect(map.count == 4);

    const actual = try map.read(3);
    std.debug.print("{d} {s}\n", .{actual.key, actual.value});
    try testing.expect(expected.key == actual.key);
}

test "MMap insert" {
    const testing = std.testing;
    const Row = extern struct {
        key: u64,
        value: [*c]const u8,
    };

    var alloc = testing.allocator;
    const testDir = testing.tmpDir(.{});
    const pathname = try testDir.dir.realpathAlloc(alloc, ".");
    defer alloc.free(pathname);
    defer testDir.dir.deleteDir(pathname) catch {};

    // given
    const key = std.hash.Murmur2_64.hash("__key__");
    var expected: Row = .{.key = key, .value = "__expected__"};
    const filename = try std.fmt.allocPrint(alloc, "{s}/{s}", .{pathname, "insert.dat"});
    defer alloc.free(filename);

    var map = try MMap(Row).init(filename, std.mem.page_size);
    defer map.deinit();

    // when
    try map.insert(0, Row{
        .key = std.hash.Murmur2_64.hash("__key_0__"),
        .value = "__value0__",
    });
    try map.insert(1, Row{
        .key = std.hash.Murmur2_64.hash("__key_1__"),
        .value = "__value1__",
    });
    try map.insert(2, Row{
        .key = std.hash.Murmur2_64.hash("__key_2__"),
        .value = "__value2__",
    });
    try map.insert(1, expected);

    // then
    try testing.expect(map.count == 4);

    var actual = try map.read(1);
    std.debug.print("{d} {s}\n", .{actual.key, actual.value});
    try testing.expect(expected.key == actual.key);
}
