const std = @import("std");
const Allocator = std.mem.Allocator;
const Timer = std.time.Timer;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Log = struct {
    alloc: Allocator,
    client: std.http.Client,
    uri: std.Uri,

    const Self = @This();

    const LogMsg = struct {
        arch: ?[]const u8,
        host: ?[]const u8,
        kernal_version: ?[]const u8,
    };

    pub fn init(alloc: Allocator, host: []const u8) Self {
        const uri = std.Uri.parse(host) catch undefined;
        return .{
            .alloc = alloc,
            .client = std.http.Client{ .allocator = alloc },
            .uri = uri,
        };
    }

    pub fn close(self: *Self) void {
        self.*.client.deinit();
    }

    // TODO(0.12): update
    // pub fn append(self: *const Self) !std.http.Client.FetchResult {
    //     const msg = HeartBeat{.host = self.*.uri.host.?};
    //     const json = try std.json.stringifyAlloc(self.*.alloc, msg, .{});
    //     const res = try self.*.c.fetch(self.alloc, .{ .location = self.*.uri, .method = .POST, .payload = json });
    //     return res;
    // }

    const errors = error {
        SendError,
    };

    pub fn basicUnameToLogMsg() LogMsg {
        const uts = std.os.uname();
        return .{
            .arch = &uts.machine,
            .host = &uts.nodename,
            .kernal_version = &uts.release,
        };
    }

    pub fn append(self: *Self, msg: *const LogMsg) !void {
        var req = try self.*.client.request(
            .POST, self.uri, std.http.Headers{.allocator = self.alloc}, .{});
        defer req.deinit();
        req.transfer_encoding = .chunked;
        try req.start();
        try std.json.stringify(msg, .{}, req.writer());
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
    const endpoint = std.os.getenv("ENDPOINT") orelse "log/append";
    const uri = try std.fmt.allocPrint(allocator, "{s}/{s}", .{host, endpoint});
    defer allocator.free(uri);
    const msg = Log.basicUnameToLogMsg();
    var logger = Log.init(allocator, uri);
    defer logger.close();
    try logger.append(&msg);
    const end = timer.read();
    std.log.info("compute-cluster agent finished in {d}ms", .{((end-start)/1_000_000)});
}