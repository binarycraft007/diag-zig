const std = @import("std");
const mem = std.mem;

pub fn dataSize(DataType: type) usize {
    const fields = std.meta.fields(DataType);
    const last_field = comptime blk: {
        if (mem.eql(u8, fields[fields.len - 1].name, "body")) {
            break :blk fields[fields.len - 2];
        }
        break :blk fields[fields.len - 1];
    };
    const last_field_size = @sizeOf(@FieldType(DataType, last_field.name));
    const bit_size = last_field_size * 8 + @bitOffsetOf(DataType, last_field.name);
    return @min(@sizeOf(DataType), bit_size / 8);
}
