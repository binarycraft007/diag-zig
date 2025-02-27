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
        const resp = try diag.sendAndRecv(efs2.Hello, gpa, iface.writer(), iface.reader());
        std.debug.print("{any}\n", .{resp});
    }

    {
        const resp = try diag.sendAndRecv(efs2.Query, gpa, iface.writer(), iface.reader());
        std.debug.print("{any}\n", .{resp});
    }

    {
        const resp = try diag.sendAndRecv(diag.SystemOperations, gpa, iface.writer(), iface.reader());
        std.debug.print("{any}\n", .{resp});
    }
}

test "simple test" {
    _ = @import("usb.zig");
    _ = @import("hdlc.zig");
}
