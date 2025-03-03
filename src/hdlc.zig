const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const testing = std.testing;

const TestData = struct {
    input: []const u8,
    output: []const u8,
};

const ESCAPE_CHAR = '\x7d';
const TRAILER_CHAR = '\x7e';

pub const Encoder = struct {
    gpa: mem.Allocator,

    pub fn encode(self: *Encoder, buf: []const u8) ![]u8 {
        var payload = try std.ArrayList(u8).initCapacity(self.gpa, buf.len * 2);
        var crc = CrcCcitt.init();
        for (buf) |b| {
            crc.update(&.{b});
            if (b == ESCAPE_CHAR or b == TRAILER_CHAR) {
                try payload.appendSlice(&.{ ESCAPE_CHAR, b ^ 0x20 });
            } else {
                try payload.append(b);
            }
        }
        const crc_final = ~crc.final();
        const crc_bytes = mem.asBytes(&crc_final);
        inline for (crc_bytes) |b| {
            if (b == ESCAPE_CHAR or b == TRAILER_CHAR) {
                try payload.appendSlice(&.{ ESCAPE_CHAR, b ^ 0x20 });
            } else {
                try payload.append(b);
            }
        }
        try payload.append(TRAILER_CHAR);

        return try payload.toOwnedSlice();
    }
};

pub const Decoder = struct {
    gpa: mem.Allocator,
    state: State = .start,
    decoded: std.ArrayList(u8),

    pub const State = enum {
        start,
        need_more,
        done,
    };

    pub const DecodeError = error{
        TrailerNotFound,
        InvalidEscapeSequence,
        InvalidPayload,
        CrcMismatch,
    };

    pub fn init(gpa: mem.Allocator) Decoder {
        return .{
            .gpa = gpa,
            .decoded = std.ArrayList(u8).init(gpa),
        };
    }

    pub fn decode(self: *Decoder, encoded: []const u8) !void {
        if (self.state == .done) return;

        try self.decoded.ensureTotalCapacity(self.decoded.items.len + encoded.len);

        self.state = .need_more;

        var i: usize = 0;
        // Process each byte until we hit the unescaped trailer char.
        while (i < encoded.len) : (i += 1) {
            const byte = encoded[i];
            if (byte == TRAILER_CHAR) {
                // End-of-packet marker found.
                self.state = .done;
                break;
            } else if (byte == ESCAPE_CHAR) {
                // Ensure there is another byte following the escape.
                i += 1;
                if (i >= encoded.len) {
                    return DecodeError.InvalidEscapeSequence;
                }
                const next_byte = encoded[i] ^ 0x20;
                try self.decoded.append(next_byte);
            } else {
                try self.decoded.append(byte);
            }
        }
    }

    pub fn result(self: *Decoder) ![]u8 {
        std.debug.assert(self.state == .done);

        // At this point, 'decoded' holds the original data with two CRC bytes appended.
        if (self.decoded.items.len < 2) {
            return DecodeError.InvalidPayload;
        }

        // Separate the CRC bytes from the data.
        const data_len = self.decoded.items.len - 2;
        const data = self.decoded.items[0..data_len];
        const crc_bytes = self.decoded.items[data_len..];

        // Compute the CRC over the data bytes.
        const computed_crc = ~CrcCcitt.hash(data);

        // This assumes that the two bytes are in the same endianness as the computed CRC.
        if (!mem.eql(u8, mem.asBytes(&computed_crc), crc_bytes)) {
            return DecodeError.CrcMismatch;
        }

        try self.decoded.resize(data_len);

        // If desired, you can return just the data or a struct containing both the data and CRC.
        // Here we return the data.
        return try self.decoded.toOwnedSlice();
    }

    pub fn deinit(self: *Decoder) void {
        self.decoded.deinit();
    }
};

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

    var encoder: Encoder = .{ .gpa = testing.allocator };
    for (test_data) |d| {
        const encoded = try encoder.encode(d.input);
        defer testing.allocator.free(encoded);
        try testing.expectEqualSlices(u8, d.output, encoded);
    }

    for (test_data) |d| {
        var decoder = Decoder.init(testing.allocator);
        defer decoder.deinit();

        try decoder.decode(d.output);
        const decoded = try decoder.result();
        defer testing.allocator.free(decoded);
        try testing.expectEqualSlices(u8, d.input, decoded);
    }
}

const CrcCcitt = std.hash.crc.Crc(u16, .{
    .polynomial = 0x1021,
    .initial = 0xffff,
    .reflect_input = true,
    .reflect_output = true,
    .xor_output = 0x0000,
});
