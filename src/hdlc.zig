const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const util = @import("util.zig");
const testing = std.testing;

const TestData = struct {
    input: []const u8,
    output: []const u8,
};

const ESCAPE_CHAR = '\x7d';
const TRAILER_CHAR = '\x7e';

pub const Encoder = struct {
    gpa: mem.Allocator,

    pub fn encode(self: *Encoder, req: anytype) ![]u8 {
        const RequestType = @TypeOf(req.*);
        const size = util.dataSize(RequestType);
        const buf = mem.asBytes(req)[0..size];
        var payload = try std.ArrayList(u8).initCapacity(self.gpa, size * 2);
        var crc = CrcCcitt.init();
        for (buf) |b| {
            crc.update(&.{b});
            if (b == ESCAPE_CHAR or b == TRAILER_CHAR) {
                try payload.appendSlice(&.{ ESCAPE_CHAR, b ^ 0x20 });
            } else {
                try payload.append(b);
            }
        }
        if (@hasField(RequestType, "body")) {
            for (mem.sliceTo(req.body, 0)) |b| {
                crc.update(&.{b});
                if (b == ESCAPE_CHAR or b == TRAILER_CHAR) {
                    try payload.appendSlice(&.{ ESCAPE_CHAR, b ^ 0x20 });
                } else {
                    try payload.append(b);
                }
            }
            crc.update(&.{0x00});
            try payload.append(0x00);
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

pub fn Decoder(comptime T: type) type {
    return struct {
        const Self = @This();
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

        pub fn init(gpa: mem.Allocator) Self {
            return .{
                .gpa = gpa,
                .decoded = std.ArrayList(u8).init(gpa),
            };
        }

        pub fn response(self: *const Self) *T.Response {
            return @ptrCast(@alignCast(self.decoded.items[0..util.dataSize(T.Response)]));
        }

        pub fn body(self: *const Self) ?[]u8 {
            const len = util.dataSize(T.Response);
            if (self.decoded.items.len <= len) return null;
            return self.decoded.items[len..];
        }

        pub fn decode(self: *Self, encoded: []const u8) !void {
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

        pub fn final(self: *Self) !void {
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
        }

        pub fn deinit(self: *const Self) void {
            self.decoded.deinit();
        }
    };
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

    var encoder: Encoder = .{ .gpa = testing.allocator };
    for (test_data) |d| {
        const encoded = try encoder.encode(d.input);
        defer testing.allocator.free(encoded);
        try testing.expectEqualSlices(u8, d.output, encoded);
    }

    //for (test_data) |d| {
    //    var decoder = Decoder.init(testing.allocator);
    //    defer decoder.deinit();

    //    try decoder.decode(d.output);
    //    const decoded = try decoder.result();
    //    defer testing.allocator.free(decoded);
    //    try testing.expectEqualSlices(u8, d.input, decoded);
    //}
}

const CrcCcitt = std.hash.crc.Crc(u16, .{
    .polynomial = 0x1021,
    .initial = 0xffff,
    .reflect_input = true,
    .reflect_output = true,
    .xor_output = 0x0000,
});
