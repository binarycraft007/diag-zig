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

    var req: diagpkt.Efs2DiagHelloReq = .{};

    const result = try hdlc.encode(gpa, req.asBytes());
    defer result.deinit();

    const end = mem.indexOfScalar(u8, result.items, '\x7e');
    _ = end;

    _ = c.libusb_init(null);
    defer c.libusb_exit(null);

    const handle = c.libusb_open_device_with_vid_pid(null, 0x2cb7, 0x010b);
    defer c.libusb_close(handle);

    if (c.libusb_kernel_driver_active(handle, 0) == 1) {
        _ = c.libusb_detach_kernel_driver(handle, 0);
    }

    _ = c.libusb_claim_interface(handle, 0);
}

test "simple test" {
    _ = @import("hdlc.zig");
}
