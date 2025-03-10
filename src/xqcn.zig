const file_version = &[_]u8{ 0x02, 0x00, 0x00, 0x00, 0x00, 0x00 };

pub fn write() !void {
    var gpa_state: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa_state.deinit();

    const gpa = gpa_state.allocator();

    var raw = std.ArrayList(u8).init(gpa);
    defer raw.deinit();
    const out = xml.streamingOutput(raw.writer());
    var writer = out.writer(gpa, .{ .indent = "  " });
    defer writer.deinit();

    const formater: HexFormater = .{ .gpa = gpa };

    try writer.xmlDeclaration("utf-8", null);
    try writer.elementStart("Storage");
    try writer.attribute("Name", "Raw");

    try writer.elementStart("Storage");
    try writer.attribute("Name", "00000334");

    try writer.elementStart("Storage");
    try writer.attribute("Name", "default");

    {
        try writer.elementStart("Storage");
        try writer.attribute("Name", "NV_NUMBERED_ITEMS");

        try writer.elementStart("Stream");
        try writer.attribute("Length", "32368");
        try writer.attribute("Name", "NV_ITEM_ARRAY");
        try writer.attribute("Value", "88 00 01 00 00 00 00");
        try writer.elementEndEmpty();

        try writer.elementStart("Stream");
        try writer.attribute("Length", "2448");
        try writer.attribute("Name", "NV_ITEM_ARRAY_SIM_1");
        try writer.attribute("Value", "88 00 01 00 00 00 00");
        try writer.elementEndEmpty();

        try writer.elementStart("Stream");
        try writer.attribute("Length", "136");
        try writer.attribute("Name", "NV_ITEM_ARRAY_SIM_2");
        try writer.attribute("Value", "88 00 01 00 00 00 00");
        try writer.elementEndEmpty();

        try writer.elementEnd();
    }

    {
        try writer.elementStart("Storage");
        try writer.attribute("Name", "EFS_Backup");

        try writer.elementStart("Storage");
        try writer.attribute("Name", "EFS_Dir");
        try writer.elementEnd();

        try writer.elementStart("Storage");
        try writer.attribute("Name", "EFS_Data");
        try writer.elementEnd();

        try writer.elementEnd();
    }

    {
        try writer.elementStart("Storage");
        try writer.attribute("Name", "NV_Items");

        try writer.elementStart("Storage");
        try writer.attribute("Name", "EFS_Dir");
        try writer.elementEnd();

        try writer.elementStart("Storage");
        try writer.attribute("Name", "EFS_Data");
        try writer.elementEnd();

        try writer.elementEnd();
    }

    {
        try writer.elementStart("Storage");
        try writer.attribute("Name", "Provisioning_Item_Files");

        try writer.elementStart("Storage");
        try writer.attribute("Name", "EFS_Dir");
        try writer.elementEnd();

        try writer.elementStart("Storage");
        try writer.attribute("Name", "EFS_Data");
        try writer.elementEnd();

        try writer.elementEnd();
    }

    {
        try writer.elementStart("Stream");
        try writer.attribute("Length", "6");
        try writer.attribute("Name", "Mobile_Property_Info");
        try writer.elementEnd();
    }

    {
        try writer.elementStart("Stream");
        try writer.attribute("Length", "6");
        try writer.attribute("Name", "Feature_Mask");
        try writer.elementEnd();
    }

    try writer.elementEnd();
    try writer.elementEnd();
    {
        var res = try formater.format(file_version);
        defer res.deinit();
        try writer.elementStart("Stream");
        try writer.attribute("Length", res.len_str);
        try writer.attribute("Name", "File_Version");
        try writer.attribute("Value", res.raw);
        try writer.elementEnd();
    }
    try writer.elementEnd();
    try writer.eof();

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{s}\n", .{raw.items});

    try bw.flush(); // Don't forget to flush!
}

const HexFormater = struct {
    gpa: std.mem.Allocator,

    pub const Result = struct {
        gpa: std.mem.Allocator,
        len_str: []const u8,
        raw: []const u8,

        pub fn deinit(self: Result) void {
            self.gpa.free(self.len_str);
            self.gpa.free(self.raw);
        }
    };

    pub fn format(self: HexFormater, str: []const u8) !Result {
        var raw = std.ArrayList(u8).init(self.gpa);
        defer raw.deinit();

        var buf: [3]u8 = undefined;
        for (str) |c| {
            const hex = try std.fmt.bufPrint(&buf, "{X:0>2} ", .{c});
            try raw.appendSlice(hex);
        }
        const len_str = try std.fmt.allocPrint(self.gpa, "{d}", .{str.len});
        return .{
            .gpa = self.gpa,
            .len_str = len_str,
            .raw = try raw.toOwnedSlice(),
        };
    }
};

const std = @import("std");
const xml = @import("xml");
