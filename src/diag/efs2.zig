const std = @import("std");
const mem = std.mem;
const hdlc = @import("../hdlc.zig");
const diag = @import("../diag.zig");
const Header = diag.Subsys.Header;

pub const fd_t = u32;
pub const mode_t = u32;

pub const max_path = 256;

pub const O_ACCMODE = 0x0003;
pub const O_RDONLY = 0x00;
pub const O_WRONLY = 0x01;
pub const O_RDWR = 0x02;
pub const O_CREAT = 0x0100;
pub const O_TRUNC = 0x01000;
pub const O_APPEND = 0x02000;
pub const O_NONBLOCK = 0x04000;

// The type of an individual "file" is encoded in its mode.  This is the
// field returned in the 'st_mode' structure on return from efs_stat() and
// friends.  The values here that correlate with Posix are the same.
// "Item" files are unique to EFS2.
pub const S_IFIFO = 0x0010000; // FIFO
pub const S_IFCHR = 0x0020000; // Character device
pub const S_IFDIR = 0x0040000; // Directory
pub const S_IFBLK = 0x0060000; // Block device
pub const S_IFREG = 0x0100000; // Regular file
pub const S_IFLNK = 0x0120000; // Symlink
pub const S_IFSOCK = 0x0140000; // Socket
pub const S_IFITM = 0x0160000; // Item File
pub const S_IFMT = 0x0170000; // Mask of all values

// "User" permissions.
pub const S_IRUSR = 0x0400; // User has Read permission.
pub const S_IWUSR = 0x0200; // User has Write permission.
pub const S_IXUSR = 0x0100; // User has eXecute permission.

// BSD definitions. */
pub const S_IREAD = S_IRUSR;
pub const S_IWRITE = S_IWUSR;
pub const S_IEXEC = S_IXUSR;

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
    };

    pub const Response = Request;
};

pub const Query = struct {
    pub const Request = packed struct {
        const Self = @This();

        header: Header = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.query),
        },
    };

    pub const Response = packed struct {
        const Self = @This();

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
    };
};

pub const Open = struct {
    pub const Request = extern struct {
        const Self = @This();

        header: Header align(1) = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.open),
        },
        oflag: u32 align(1) = 0,
        mode: mode_t align(1) = 0,
        body: [*:0]const u8,
    };

    pub const Response = packed struct {
        const Self = @This();

        header: Header = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.open),
        },
        fd: fd_t = 0,
        errno: u32 = 0,
    };
};

pub const Close = struct {
    pub const Request = extern struct {
        const Self = @This();

        header: Header align(1) = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.close),
        },
        fd: fd_t align(1) = 0,
    };

    pub const Response = packed struct {
        const Self = @This();

        header: Header = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.open),
        },
        errno: u32 = 0,
    };
};

pub const OpenDir = struct {
    pub const Request = extern struct {
        const Self = @This();

        header: Header align(1) = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.opendir),
        },
        body: [*:0]const u8,
    };

    pub const Response = packed struct {
        const Self = @This();

        header: Header = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.opendir),
        },
        fd: fd_t = 0,
        errno: u32 = 0,
    };
};

pub const CloseDir = struct {
    pub const Request = extern struct {
        const Self = @This();

        header: Header align(1) = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.closedir),
        },
        fd: fd_t align(1) = 0,
    };

    pub const Response = packed struct {
        const Self = @This();

        header: Header = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.open),
        },
        errno: u32 = 0,
    };
};

pub const FStat = struct {
    pub const Request = extern struct {
        const Self = @This();

        header: Header align(1) = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.fstat),
        },
        fd: fd_t align(1) = 0,
    };

    pub const Response = packed struct {
        const Self = @This();

        header: Header = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.fstat),
        },
        errno: u32 = 0,
        mode: mode_t = 0,
        size: u32 = 0,
        nlink: u32 = 0,
        atime: u32 = 0,
        mtime: u32 = 0,
        ctime: u32 = 0,
    };
};

pub const Read = struct {
    pub const Request = extern struct {
        const Self = @This();

        header: Header align(1) = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.read),
        },
        fd: fd_t align(1) = 0,
        nbyte: u32 = 0,
        offset: u32 = 0,
    };

    pub const Response = packed struct {
        const Self = @This();

        header: Header = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.read),
        },
        fd: fd_t = 0,
        offset: u32 = 0,
        bytes_read: u32 = 0,
        errno: u32 = 0,
    };
};

pub const ReadDir = struct {
    pub const Request = extern struct {
        const Self = @This();

        header: Header align(1) = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.readdir),
        },
        fd: fd_t align(1) = 0,
        seq_no: u32 = 0,
    };

    pub const EntryType = enum(u32) {
        file,
        directory,
        symlink,
    };

    pub const Response = packed struct {
        const Self = @This();

        header: Header = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.readdir),
        },
        fd: fd_t = 0,
        seq_no: u32 = 0,
        offset: u32 = 0,
        errno: u32 = 0,
        entry_type: EntryType = .file,
        mode: mode_t = 0,
        size: u32 = 0,
        atime: u32 = 0,
        mtime: u32 = 0,
        ctime: u32 = 0,
        // entry_name in body
    };
};

pub const Get = struct {
    pub const Request = extern struct {
        const Self = @This();

        header: Header align(1) = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.get),
        },
        data_length: u32 align(1) = 0,
        path_length: u32 align(1) = 0,
        seq_no: u16 align(1) = 0,
    };

    pub const Response = packed struct {
        const Self = @This();

        header: Header = .{
            .cmd_code = @intFromEnum(diag.Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(diag.Subsys.fs),
            .subsys_cmd_code = @intFromEnum(Command.get),
        },
        num_bytes: u32 = 0,
        errno: u32 = 0,
        seq_no: u16 = 0,
        // data in body
    };
};
