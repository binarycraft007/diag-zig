const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const diagpkt = @import("diagpkt.zig");
const hdlc = @import("hdlc.zig");
const c = @import("c");

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    var port: ?*c.sp_port = null;
    assert(c.sp_get_port_by_name("/dev/ttyUSB0", &port) == c.SP_OK);
    assert(c.sp_open(port, c.SP_MODE_READ_WRITE) == c.SP_OK);
    assert(c.sp_set_baudrate(port, 115200) == c.SP_OK);

    var req: diagpkt.Efs2DiagHelloReq = .{};

    const result = try hdlc.encode(gpa, req.asBytes());
    defer result.deinit();

    const end = mem.indexOfScalar(u8, result.items, '\x7e');

    _ = c.sp_blocking_write(port, result.items.ptr, end.?, 3000);

    var buf = try std.ArrayList(u8).initCapacity(gpa, diagpkt.Efs2DiagHelloRsp.size * 2);
    defer buf.deinit();
    buf.expandToCapacity();

    _ = c.sp_blocking_read(port, buf.items.ptr, buf.items.len, 3000);

    std.debug.print("{x}\n", .{buf.items});
}

test "simple test" {
    _ = @import("hdlc.zig");
}
