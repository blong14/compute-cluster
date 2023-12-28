const std = @import("std");
const Allocator = std.mem.Allocator;
const Timer = std.time.Timer;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Logger = struct {
    alloc: Allocator,
    c: std.http.Client,
    uri: std.Uri,

    const Self = @This();

    const LogMsg = struct {
        host: ?[]const u8
    };

    pub fn init(alloc: Allocator, host: []const u8) Self {
        const uri = std.Uri.parse(host) catch unreachable;
        return .{
            .c = std.http.Client{ .allocator = alloc },
            .alloc = alloc,
            .uri = uri,
        };
    }

    pub fn close(self: *Self) void {
        self.*.c.deinit();
    }

    // TODO(0.12): update
    // pub fn send(self: *const Self) !std.http.Client.FetchResult {
    //     const msg = HeartBeat{.host = self.*.uri.host.?};
    //     const json = try std.json.stringifyAlloc(self.*.alloc, msg, .{});
    //     const res = try self.*.c.fetch(self.alloc, .{ .location = self.*.uri, .method = .POST, .payload = json });
    //     return res;
    // }

    const errors = error {
        SendError,
    };

    pub fn write(self: *Self) !void {
        var req = try self.*.c.request(.POST, self.uri, std.http.Headers{.allocator = self.alloc}, .{});
        defer req.deinit();
        req.transfer_encoding = .chunked;
        try req.start();
        var name_buffer: [std.os.HOST_NAME_MAX]u8 = undefined;
        var host = std.os.gethostname(&name_buffer) catch "localhost";
        try std.json.stringify(LogMsg{.host = host}, .{}, req.writer());
        try req.finish();
        try req.wait();
        switch(req.response.status) {
            std.http.Status.accepted,
            std.http.Status.created,
            std.http.Status.ok => {
                return;
            },
            else => {
                std.debug.print("error: response satus {d}\n", .{req.response.status});
                return errors.SendError;
            }
        }
    }
};

pub fn main() !void {
    std.log.info("compute-cluster agent started...", .{});
    var timer = try Timer.start();
    const start = timer.read();
    const host = std.os.getenv("HOST") orelse "http://localhost:8080";
    const endpoint = std.os.getenv("ENDPOINT") orelse "log";
    const uri = try std.fmt.allocPrint(allocator, "{s}/{s}", .{host, endpoint});
    defer allocator.free(uri);
    var logger = Logger.init(allocator, uri);
    defer logger.close();
    try logger.write();
    const end = timer.read();
    std.log.info("compute-cluster agent finished in {d}ms", .{((end-start)/1_000_000)});
}