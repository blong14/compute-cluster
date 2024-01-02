const std = @import("std");
const Allocator = std.mem.Allocator;
const Timer = std.time.Timer;

const Log = struct {
    alloc: Allocator,
    client: std.http.Client,
    uri: std.Uri,

    const Self = @This();

    const Msg = struct {
        arch: []const u8,
        host: []const u8,
        kernal_version: []const u8,
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

    pub fn append(self: *Self, msg: Msg) !void {
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

pub fn getArchName(name_buffer: *[std.os.NAME_MAX]u8) []const u8 {
    const uts = std.os.uname();
    const machine = std.mem.sliceTo(&uts.machine, 0);
    std.debug.assert(machine.len <= name_buffer.len);
    const result = name_buffer[0..machine.len];
    @memcpy(result, machine);
    return result;
}

pub fn getHostName(name_buffer: *[std.os.HOST_NAME_MAX]u8) []const u8 {
    const uts = std.os.uname();
    const hostname = std.mem.sliceTo(&uts.nodename, 0);
    std.debug.assert(hostname.len <= name_buffer.len);
    const result = name_buffer[0..hostname.len];
    @memcpy(result, hostname);
    return result;
}

pub fn getKernalVersion(name_buffer: *[std.os.NAME_MAX]u8) []const u8 {
    const uts = std.os.uname();
    const release = std.mem.sliceTo(&uts.release, 0);
    std.debug.assert(release.len <= name_buffer.len);
    const result = name_buffer[0..release.len];
    @memcpy(result, release);
    return result;
}

pub fn main() !void {
    std.log.info("compute-cluster agent started...", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var timer = try Timer.start();
    const start = timer.read();

    const dsn = std.os.getenv("HOST") orelse "http://localhost:8080";
    const endpoint = std.os.getenv("ENDPOINT") orelse "log/append";
    const uri = try std.fmt.allocPrint(allocator, "{s}/{s}", .{dsn, endpoint});
    defer allocator.free(uri);

    var arch_buf: [std.os.NAME_MAX]u8 = undefined;
    const arch = getArchName(&arch_buf);

    var host_buf: [std.os.HOST_NAME_MAX]u8 = undefined;
    const host = getHostName(&host_buf);

    var kv_buf: [std.os.NAME_MAX]u8 = undefined;
    const kv = getKernalVersion(&kv_buf);

    var logger = Log.init(allocator, uri);
    defer logger.close();

    const msg = Log.Msg{
        .arch = arch,
        .host = host,
        .kernal_version = kv,
    };
    try logger.append(msg);

    const end = timer.read();
    std.log.info("compute-cluster agent finished in {d}ms", .{((end-start)/1_000_000)});
}