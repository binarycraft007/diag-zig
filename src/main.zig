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
        var req: efs2.Hello.Request = .{};
        try req.send(gpa, iface.writer());
        const resp = try efs2.Hello.Response.recv(gpa, iface.reader());
        std.debug.print("{any}\n", .{resp});
    }

    {
        var req: efs2.Query.Request = .{};
        try req.send(gpa, iface.writer());
        const resp = try efs2.Query.Response.recv(gpa, iface.reader());
        std.debug.print("{any}\n", .{resp});
    }
}

test "simple test" {
    _ = @import("usb.zig");
    _ = @import("hdlc.zig");
}
