const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const diagpkt = @import("diagpkt.zig");
const hdlc = @import("hdlc.zig");
const usb = @import("usb.zig");

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    var req: diagpkt.Efs2DiagHelloReq = .{};

    const result = try hdlc.encode(gpa, req.asBytes());
    defer result.deinit();

    const end = mem.indexOfScalar(u8, result.items, '\x7e').? + 1;

    try usb.init();
    defer usb.deinit();

    var iface = try usb.Interface.autoFind();
    defer iface.deinit();

    _ = try iface.write(result.items[0..end]);
}

test "simple test" {
    _ = @import("usb.zig");
    _ = @import("hdlc.zig");
}
