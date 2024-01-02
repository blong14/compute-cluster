const std = @import("std");
const Allocator = std.mem.Allocator;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const LogMsg = struct {
    arch: []const u8,
    host: []const u8,
    kernal_version: []const u8,
};

const Log = struct {
    alloc: Allocator,
    client: std.http.Client,
    uri: std.Uri,

    const Self = @This();

    pub fn init(alloc: Allocator, host: []const u8) !Self {
        const uri = try std.Uri.parse(host);
        return .{
            .alloc = alloc,
            .uri = uri,
        };
    }

    pub fn close(self: Self) void {
        self.*.client.close();
    }
};

pub fn appendToLog(logger: *Log, msg: LogMsg) !void {
    _ = logger;
    _ = msg;

}

pub fn main() !void {
    var name: [std.os.HOST_NAME_MAX]u8 = undefined;
    var host = try std.os.gethostname(name);

    const logger = Log.init(allocator, host);
    defer logger.close();
    const msg = LogMsg{
        .arch = arch,
        .host = host,
        .kernal_version = kernal_version,
    };
    try appendToLog(logger, msg);
}