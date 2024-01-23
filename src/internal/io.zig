const std = @import("std");

const SSTable = @import("./io/file.zig").SSTable;

pub fn ssTable(path: []const u8) SSTable {
    return SSTable.init(path, std.mem.page_size);
}

pub fn ssTableWithCapacity(path: []const u8, capacity: usize) SSTable {
    return SSTable.init(path, capacity);
}
