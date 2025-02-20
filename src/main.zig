const std = @import("std");
const assert = std.debug.assert;
const c = @import("c");

pub fn main() !void {
    var port: ?*c.sp_port = null;
    assert(c.sp_get_port_by_name("/dev/ttyUSB0", &port) == c.SP_OK);
    assert(c.sp_open(port, c.SP_MODE_READ_WRITE) == c.SP_OK);
    assert(c.sp_set_baudrate(port, 115200) == c.SP_OK);
}

test "simple test" {
    _ = @import("hdlc.zig");
}
