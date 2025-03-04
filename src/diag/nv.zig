const std = @import("std");
const mem = std.mem;
const hdlc = @import("../hdlc.zig");
const diag = @import("../diag.zig");
const filter: Filter = @import("qcn_filter.zon");

const Filter = struct {
    pub const NvList = struct {
        category: []const u8,
        id: u16,
        num: u8,
    };
    nv_list: []const NvList,
};

const nv_item_size = 128;
const max_nv_id = 7233;

pub const Stat = enum(u16) {
    done, // Request was completed.
    busy, // Request is queued.
    badcmd, // Unrecognizable command field.
    full, // NVM is full.
    fail, // Command failed for a reason other than NVM full.
    notactive, // Variable was not active.
    badparm, // Bad parameter in the command block.
    readonly, // Parameter is write-protected and thus read-only.
    badtg, // Item is not valid for this target.
    nomem, // Free memory has been exhausted.
    notalloc, // Address is not a valid allocation.
    ruim_not_supported, // NV item is not supported in RUIM
    _,
};

pub const Read = struct {
    request: Request = .{ .item = max_nv_id },
    response: Response = .{ .item = max_nv_id },

    pub const Header = packed struct {
        cmd_code: u8 = @intFromEnum(diag.Command.nv_read_f),
    };

    pub const Request = extern struct {
        const Self = @This();

        header: Header align(1) = .{},
        item: u16 align(1), // Which item - use nv_items_enum_type
        item_data: [nv_item_size]u8 align(1) = [_]u8{0} ** nv_item_size, // Item itself - use nv_item_type
        nv_stat: Stat align(1) = .done, // Status of operation
    };

    pub const Response = Request;
};

pub const ReadExt = struct {
    request: Request = .{ .item = max_nv_id },
    response: Response = .{ .item = max_nv_id },

    pub const Request = extern struct {
        const Self = @This();

        header: diag.Subsys.Header align(1) = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.nv),
            .subsys_cmd_code = diag.Subsys.nv_read_ext_f,
        },
        item: u16 align(1), // Which item - use nv_items_enum_type
        context: u16 align(1) = 0,
        item_data: [nv_item_size]u8 align(1) = [_]u8{0} ** nv_item_size, // Item itself - use nv_item_type
        nv_stat: Stat align(1) = .done, // Status of operation - use nv_stat_enum_type
    };

    pub const Response = Request;
};

pub const Write = struct {
    request: Request = .{ .item = max_nv_id },
    response: Response = .{ .item = max_nv_id },

    pub const Header = packed struct {
        cmd_code: u8 = @intFromEnum(diag.Command.nv_write_f),
    };

    pub const Request = extern struct {
        const Self = @This();

        header: Header align(1) = .{},
        item: u16 align(1), // Which item - use nv_items_enum_type
        item_data: [nv_item_size]u8 align(1) = [_]u8{0} ** nv_item_size, // Item itself - use nv_item_type
        nv_stat: Stat align(1) = .done, // Status of operation
    };

    pub const Response = Request;
};

pub const WriteExt = struct {
    request: Request = .{ .item = max_nv_id },
    response: Response = .{ .item = max_nv_id },

    pub const Request = extern struct {
        const Self = @This();

        header: diag.Subsys.Header align(1) = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.nv),
            .subsys_cmd_code = diag.Subsys.nv_write_ext_f,
        },
        item: u16 align(1), // Which item - use nv_items_enum_type
        context: u16 align(1) = 0,
        item_data: [nv_item_size]u8 align(1) = [_]u8{0} ** nv_item_size, // Item itself - use nv_item_type
        nv_stat: Stat align(1) = .done, // Status of operation - use nv_stat_enum_type
    };

    pub const Response = Request;
};

pub const ItemEntry = extern struct {
    len: u16 align(1) = @sizeOf(@This()),
    flags: u16 align(1) = 0x01,
    code: u16 align(1),
    index: u16 align(1) = 0x00,
    data: [nv_item_size]u8 align(1),
};

pub fn backup(gpa: mem.Allocator, driver: anytype) !void {
    var legacy_nv: usize = 0;
    for (filter.nv_list) |nv_item| {
        const resp = diag.sendAndRecv(Read, .{ .item = nv_item.id }, gpa, driver) catch |err| switch (err) {
            error.BadParameter, error.BadLength => continue,
            else => |e| return e,
        };
        if (resp.response.nv_stat == .done) {
            legacy_nv += 1;
        }
    }

    var sim_1_nv: usize = 0;
    for (filter.nv_list) |nv_item| {
        const resp = diag.sendAndRecv(ReadExt, .{ .item = nv_item.id, .context = 1 }, gpa, driver) catch |err| switch (err) {
            error.BadParameter, error.BadLength => continue,
            else => |e| return e,
        };
        if (resp.response.nv_stat == .done) {
            sim_1_nv += 1;
        }
    }

    var sim_2_nv: usize = 0;
    for (filter.nv_list) |nv_item| {
        const resp = diag.sendAndRecv(ReadExt, .{ .item = nv_item.id, .context = 2 }, gpa, driver) catch |err| switch (err) {
            error.BadParameter, error.BadLength => continue,
            else => |e| return e,
        };
        if (resp.response.nv_stat == .done) {
            sim_2_nv += 1;
        }
    }
}
