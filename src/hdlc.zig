const std = @import("std");
const mem = std.mem;
const c = @import("c");
const assert = std.debug.assert;
const testing = std.testing;

const TestData = struct {
    input: []const u8,
    output: []const u8,
};

pub const Payload = std.ArrayList(u8);

pub fn encode(gpa: mem.Allocator, buf: []const u8) !Payload {
    var payload = try Payload.initCapacity(gpa, buf.len * 2);
    payload.expandToCapacity();

    // Set up the send descriptor */
    var src_desc: c.diag_send_desc_type = .{
        .pkt = buf.ptr,
        .last = &buf[buf.len - 1],
        .state = c.DIAG_STATE_START,
        .terminate = 1, // Signal that we want to terminate the packet
    };

    // Set up the destination structure */
    var enc: c.diag_hdlc_dest_type = .{
        .dest = payload.items.ptr,
        .dest_last = &payload.items[payload.items.len - 1],
        .crc = 0xffff, // Start with the defined CRC seed
    };

    // Encode the DIAG packet */
    c.diag_hdlc_encode(&src_desc, &enc);
    return payload;
}

pub fn decode(gpa: mem.Allocator, buf: []const u8) !Payload {
    var payload = try Payload.initCapacity(gpa, buf.len);
    payload.expandToCapacity();

    var hdlc: c.diag_hdlc_decode_type = .{
        .src_ptr = @constCast(buf.ptr),
        .dest_ptr = payload.items.ptr,
        .src_size = @intCast(buf.len),
        .dest_size = @intCast(payload.items.len),
        .src_idx = 0,
        .dest_idx = 0,
        .escaping = 0,
    };

    // Decode the packet.
    assert(c.diag_hdlc_decode(&hdlc) == c.HDLC_COMPLETE);
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
        try testing.expectEqualSlices(u8, encoded.items[0..d.output.len], d.output);
    }

    for (test_data) |d| {
        var decoded = try decode(testing.allocator, d.output);
        defer decoded.deinit();
        try testing.expectEqualSlices(u8, decoded.items[0..d.input.len], d.input);
    }
}
