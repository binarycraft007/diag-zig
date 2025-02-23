const std = @import("std");
const mem = std.mem;
const c = @import("c");
const assert = std.debug.assert;
const testing = std.testing;

const TestData = struct {
    input: []const u8,
    output: []const u8,
};

pub const Payload = struct {
    const Buf = std.ArrayList(u8);

    buf: Buf,
    size: usize = 0,

    pub fn init(gpa: mem.Allocator, cap: usize) !Payload {
        var buf = try Buf.initCapacity(gpa, cap);
        buf.expandToCapacity();
        return .{ .buf = buf };
    }

    pub fn deinit(self: *Payload) void {
        self.buf.deinit();
    }

    pub fn bytes(self: *Payload) []const u8 {
        return self.buf.items[0..self.size];
    }
};

pub fn encode(gpa: mem.Allocator, buf: []const u8) !Payload {
    var payload = try Payload.init(gpa, buf.len * 2);

    // Set up the send descriptor
    var src_desc: c.diag_send_desc_type = .{
        .pkt = buf.ptr,
        .last = &buf[buf.len - 1],
        .state = c.DIAG_STATE_START,
        .terminate = 1, // Signal that we want to terminate the packet
    };

    // Set up the destination structure
    var enc: c.diag_hdlc_dest_type = .{
        .dest = payload.buf.items.ptr,
        .dest_last = &payload.buf.items[payload.buf.items.len - 1],
        .crc = 0xffff, // Start with the defined CRC seed
    };

    // Encode the DIAG packet
    c.diag_hdlc_encode(&src_desc, &enc);
    payload.size = mem.indexOfScalar(u8, payload.buf.items, '\x7e').? + 1;

    return payload;
}

pub fn decode(gpa: mem.Allocator, buf: []const u8) !Payload {
    var payload = try Payload.init(gpa, buf.len);

    var hdlc: c.diag_hdlc_decode_type = .{
        .src_ptr = @constCast(buf.ptr),
        .dest_ptr = payload.buf.items.ptr,
        .src_size = @intCast(buf.len),
        .dest_size = @intCast(payload.buf.items.len),
        .src_idx = 0,
        .dest_idx = 0,
        .escaping = 0,
    };

    // Decode the packet.
    const ret = c.diag_hdlc_decode(&hdlc);
    _ = ret;
    payload.size = hdlc.dest_idx - 3;

    return payload;
}

test "hdlc encode" {
    const test_data = [_]TestData{
        .{
            .input = &.{ 0x73, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
            .output = &.{ 0x73, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xda, 0x81, 0x7e },
        },
        .{
            .input = &.{ 0x7d, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
            .output = &.{ 0x7d, 0x5d, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x74, 0x41, 0x7e },
        },
    };

    for (test_data) |d| {
        var encoded = try encode(testing.allocator, d.input);
        defer encoded.deinit();
        try testing.expectEqualSlices(u8, d.output, encoded.bytes());
    }

    for (test_data) |d| {
        var decoded = try decode(testing.allocator, d.output);
        defer decoded.deinit();
        try testing.expectEqualSlices(u8, d.input, decoded.bytes());
    }
}
