const std = @import("std");

const MMap = @import("./mmap.zig").MMap;

const Allocator = std.mem.Allocator;

const SSTable = struct {
    const Row = struct {
        key: u64,
        value: [*c]const u8,
    };

    data: MMap(Row),

    const Self = @This();

    const Error = error{
        NotFound,
    } || MMap(Row).Error;

    pub fn init(path: []const u8, capacity: usize) Error!Self {
        var data = try MMap(Row).init(path, capacity);
        return .{.data = data};
    }

    fn findIndex(self: Self, key: u64, low: usize, high: usize) usize {
        if (high < low) {
            return high + 1;
        }
        const mid = (low + high) / 2;
        const entry = self.data.read(mid) catch |err| {
            std.debug.print("Oops {s}\n", .{@errorName(err)});
            return -1;
        };
        if (key < entry.key) {
            return self.findIndex(key, low, mid - 1);
        } else if (key == entry.key) {
            return mid;
        } else {
            return self.findIndex(key, mid + 1, high);
        }
    }

    fn equalto(self: Self, key: u64, idx: usize) bool {
        const entry = self.data.read(idx) catch |err| {
            std.debug.print("Oops {s}\n", .{@errorName(err)});
            return false;
        };
        return key == entry.key;
    }

    fn greaterthan(self: Self, key: u64, idx: usize) bool {
        const entry = self.data.read(idx) catch |err| {
            std.debug.print("Oops {s}\n", .{@errorName(err)});
            return false;
        };
        return key > entry.key;
    }

    pub fn read(self: Self, key: []const u8, dest: []u8) Error!void {
        const k: u64 = std.hash.Murmur2_64.hash(key);
        const count = self.data.count;
        if (count == 0) return Error.NotFound;
        const idx = self.findIndex(k, 0, count - 1);
        if ((idx == -1) or (idx == count)) return Error.NotFound;
        const value = try self.data.read(idx).value;
        @memcpy(dest, value);
    }

    pub fn write(self: *Self, key: []const u8, value: []const u8) Error!void {
        const k: u64 = std.hash.Murmur2_64.hash(key);
        const count: usize = self.data.count;
        if ((count == 0) or (self.greaterthan(k, count - 1))) {
            return try self.data.append(Row{ .key = k, .value = value });
        }
        const idx = self.findIndex(k, 0, count - 1);
        try self.data.insert(idx, Row{ .key = k, .value = value });
    }
};

test SSTable {
    const testing = std.testing;

    var alloc = testing.allocator;
    const testDir = testing.tmpDir(.{});
    const pathname = try testDir.dir.realpathAlloc(alloc, ".");
    defer alloc.free(pathname);
    defer testDir.dir.deleteDir(pathname) catch {};

    // given
    const filename = try std.fmt.allocPrint(alloc, "{s}/{s}", .{pathname, "sstable.dat"});
    defer alloc.free(filename);
    var st = try SSTable.init(filename, std.mem.page_size);

    // when
    try st.write("__key__", "__value__");

    // then
    var value: [256]u8 = undefined;
    try st.read("__key__", &value);
    try testing.expect(std.mem.eql(u8, &value, "__value__"));
}
