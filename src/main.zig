const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const diag = @import("diag.zig");
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
        const resp = try diag.sendAndRecv(diag.NvRead, .{ .item = 0 }, gpa, &iface);
        std.debug.print("{any}\n", .{resp});
    }

    {
        const resp = try diag.sendAndRecv(diag.NvReadExt, .{ .item = 6372, .context = 2 }, gpa, &iface);
        std.debug.print("{any}\n", .{resp});
    }

    {
        const resp = try diag.sendAndRecv(efs2.Hello, .{}, gpa, &iface);
        std.debug.print("{any}\n", .{resp});
    }

    {
        const resp = try diag.sendAndRecv(efs2.Query, .{}, gpa, &iface);
        std.debug.print("{any}\n", .{resp});
    }

    {
        const resp = try diag.sendAndRecv(diag.FeatureQuery, .{}, gpa, &iface);
        std.debug.print("{any}\n", .{resp});
    }
}

test "simple test" {
    _ = @import("usb.zig");
    _ = @import("hdlc.zig");
}
