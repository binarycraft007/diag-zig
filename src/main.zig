const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const diag = @import("diag.zig");
const nv = diag.nv;
const efs2 = diag.efs2;
const usb = @import("usb.zig");

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    var ctx = try usb.Context.init();
    defer ctx.deinit();

    var iface = try usb.Interface.autoFind();
    defer iface.deinit();

    {
        const resp = try diag.sendAndRecv(diag.Loopback, .{}, gpa, &iface);
        std.debug.print("{any}\n", .{resp});
    }

    {
        const resp = try diag.sendAndRecv(diag.VersionInfo, .{}, gpa, &iface);
        std.debug.print("{any}\n", .{resp});
    }

    {
        const resp = try diag.sendAndRecv(diag.ServiceProgramming, .{}, gpa, &iface);
        std.debug.print("{any}\n", .{resp});
    }

    {
        const resp = try diag.sendAndRecv(diag.ExtBuildId, .{}, gpa, &iface);
        std.debug.print("{any}\n", .{resp});
    }

    {
        const path = "/nv/item_store/rfnv/rfnv.bl";
        var req: efs2.Open.Request = .{};
        @memcpy(req.path[0..path.len], path);
        const resp = try diag.sendAndRecv(efs2.Open, req, gpa, &iface);
        std.debug.print("{any}\n", .{resp});

        const resp1 = try diag.sendAndRecv(efs2.Close, .{ .fd = resp.response.fd }, gpa, &iface);
        std.debug.print("{any}\n", .{resp1});
    }

    //try nv.backup(gpa, &iface);
}

test "simple test" {
    _ = @import("usb.zig");
    _ = @import("hdlc.zig");
}
