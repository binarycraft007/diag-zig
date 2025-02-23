const std = @import("std");
const mem = std.mem;
const hdlc = @import("../hdlc.zig");
const diag = @import("../diag.zig");

pub const Header = packed struct {
    cmd_code: u8,
    subsys_id: u8,
    subsys_cmd_code: u16,
};

pub const Command = enum(u16) {
    hello = 0,
    query = 1,
    open = 2,
    close = 3,
    read = 4,
    write = 5,
    symlink = 6,
    readlink = 7,
    unlink = 8,
    mkdir = 9,
    rmdir = 10,
    opendir = 11,
    readdir = 12,
    closedir = 13,
    rename = 14,
    stat = 15,
    lstat = 16,
    fstat = 17,
    chmod = 18,
    statfs = 19,
    access = 20,
    dev_info = 21,
    fact_image_start = 22,
    fact_image_read = 23,
    fact_image_end = 24,
    prep_fact_image = 25,
    put_deprecated = 26,
    get_deprecated = 27,
    @"error" = 28,
    extended_info = 29,
    chown = 30,
    benchmark_start_test = 31,
    benchmark_get_results = 32,
    benchmark_init = 33,
    set_reservation = 34,
    set_quota = 35,
    get_group_info = 36,
    deltree = 37,
    put = 38,
    get = 39,
    truncate = 40,
    ftruncate = 41,
    statvfs_v2 = 42,
    md5sum = 43,
    hotplug_format = 44,
    shred = 45,
    set_idle_dev_evt_dur = 46,
    hotplug_device_info = 47,
    sync_no_wait = 48,
    sync_get_status = 49,
    truncate64 = 50,
    ftruncate64 = 51,
    lseek64 = 52,
    make_golden_copy = 53,
    filesystem_image_open = 54,
    filesystem_image_read = 55,
    filesystem_image_close = 56,
    make_golden_copy_v2 = 57,
    make_golden_copy_v2_get_status = 58,
    make_fs_backup_copy = 59,
    make_fs_backup_copy_get_status = 60,
};

pub const Hello = struct {
    pub const Request = packed struct {
        const Self = @This();

        pub const size = @bitOffsetOf(Self, "padding") / 8;

        header: Header = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.hello),
        },
        targ_pkt_window: u32 = 0x100000, // Window size in packets for sends from phone
        targ_byte_window: u32 = 0x100000, // Window size in bytes for sends from phone
        host_pkt_window: u32 = 0x100000, // Window size in packets for sends from host
        host_byte_window: u32 = 0x100000, // Window size in bytes for sends from host
        iter_pkt_window: u32 = 0x100000, // Window size in packets for dir iteration
        iter_byte_window: u32 = 0x100000, // Window size in bytes for dir iteration
        version: u32 = 1, // Protocol version number
        min_version: u32 = 1, // Smallest supported protocol version number
        max_version: u32 = 1, // Highest supported protocol version number
        feature_bits: u32 = 0xffffffff, // Feature bit mask; one bit per feature
        padding: u32 = 0,

        pub fn asBytes(self: *Self) []const u8 {
            return mem.asBytes(self)[0..size];
        }

        pub fn send(self: *Self, gpa: mem.Allocator, writer: anytype) !void {
            var result = try hdlc.encode(gpa, self.asBytes());
            defer result.deinit();

            try writer.writeAll(result.bytes());
        }

        pub fn recv(gpa: mem.Allocator, reader: anytype) !Self {
            var buf: [512]u8 = undefined;
            const amt = try reader.read(&buf);
            var result = try hdlc.decode(gpa, buf[0..amt]);
            defer result.deinit();

            var resp: Self = .{};
            @memcpy(mem.asBytes(&resp)[0..size], result.bytes()[0..size]);
            return resp;
        }
    };

    pub const Response = Request;
};

pub const Query = struct {
    pub const Request = packed struct {
        const Self = @This();

        pub const size = @bitOffsetOf(Self, "padding") / 8;

        header: Header = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.query),
        },
        padding: u32 = 0,

        pub fn asBytes(self: *Self) []const u8 {
            return mem.asBytes(self)[0..size];
        }

        pub fn send(self: *Self, gpa: mem.Allocator, writer: anytype) !void {
            var result = try hdlc.encode(gpa, self.asBytes());
            defer result.deinit();

            try writer.writeAll(result.bytes());
        }
    };

    pub const Response = packed struct {
        const Self = @This();

        pub const size = @bitOffsetOf(Self, "padding") / 8;

        header: Header = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.query),
        },

        max_name: u32 = 0, // Maximum filename length
        max_path: u32 = 0, // Maximum pathname length
        max_link_depth: u32 = 0, // Maximum number of symlinks followed
        max_file_size: u32 = 0, // Maximum size of a file in bytes
        max_dir_entries: u32 = 0, // Maximum number of entries in a directory
        max_mounts: u32 = 0, // Maximum number of filesystem mounts
        padding: u32 = 0,

        pub fn asBytes(self: *Self) []const u8 {
            return mem.asBytes(self)[0..size];
        }

        pub fn recv(gpa: mem.Allocator, reader: anytype) !Self {
            var buf: [512]u8 = undefined;
            const amt = try reader.read(&buf);
            var result = try hdlc.decode(gpa, buf[0..amt]);
            defer result.deinit();

            var resp: Self = .{};
            @memcpy(mem.asBytes(&resp)[0..size], result.bytes()[0..size]);
            return resp;
        }
    };
};
