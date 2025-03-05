const std = @import("std");

pub fn dataSize(DataType: type) usize {
    const fields = std.meta.fields(DataType);
    const last_field = fields[fields.len - 1];
    const last_field_size = @sizeOf(@FieldType(DataType, last_field.name));
    const bit_size = last_field_size * 8 + @bitOffsetOf(DataType, last_field.name);
    return @min(@sizeOf(DataType), bit_size / 8);
}
