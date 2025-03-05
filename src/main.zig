const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const diag = @import("diag.zig");
const nv = diag.nv;
const efs2 = diag.efs2;
const log = std.log.scoped(.main);

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    var client = try diag.Client.init(gpa, .usb);
    defer client.deinit();

    {
        const decoder = try client.send(diag.Loopback, .{});
        defer decoder.deinit();
    }

    {
        const decoder = try client.send(diag.VersionInfo, .{});
        defer decoder.deinit();
    }

    {
        const decoder = try client.send(diag.ServiceProgramming, .{});
        defer decoder.deinit();
    }

    {
        const decoder = try client.send(diag.ExtBuildId, .{});
        defer decoder.deinit();
        if (decoder.body()) |body| log.info("{s}", .{body});
    }

    {
        const decoder = try client.send(efs2.Hello, .{});
        defer decoder.deinit();
    }

    {
        const decoder = try client.send(efs2.Query, .{});
        defer decoder.deinit();
    }

    var fd: efs2.fd_t = 0;
    var size: u32 = 0;
    {
        const decoder = try client.send(efs2.Open, .{ .body = "/nv/item_store/rfnv/rfnv.bl" });
        defer decoder.deinit();
        fd = decoder.response().fd;
    }
    {
        const decoder = try client.send(efs2.FStat, .{ .fd = fd });
        defer decoder.deinit();
        size = decoder.response().size;
    }
    {
        const decoder = try client.send(efs2.Read, .{ .fd = fd, .nbyte = size });
        defer decoder.deinit();
        if (decoder.body()) |body| log.info("{s}", .{body});
    }
    {
        const decoder = try client.send(efs2.Close, .{ .fd = fd });
        defer decoder.deinit();
    }

    //try client.backup();
}

test "simple test" {
    _ = @import("usb.zig");
    _ = @import("hdlc.zig");
}
