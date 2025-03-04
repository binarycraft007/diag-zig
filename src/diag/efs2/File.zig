handle: Handle,

pub const Handle = efs2.fd_t;
pub const Mode = efs2.mode_t;

pub const Kind = enum(u32) {
    file,
    directory,
    sym_link,
};

pub const default_mode = 0o666;

pub const OpenError = error{
    SharingViolation,
    PathAlreadyExists,
    FileNotFound,
    AccessDenied,
    PipeBusy,
    NoDevice,
    BadPathName,
    Unexpected,
};

pub const OpenMode = enum {
    read_only,
    write_only,
    read_write,
};

pub const OpenFlags = struct {
    mode: OpenMode = .read_only,

    pub fn isRead(self: OpenFlags) bool {
        return self.mode != .write_only;
    }

    pub fn isWrite(self: OpenFlags) bool {
        return self.mode != .read_only;
    }
};

pub const CreateFlags = struct {
    /// Whether the file will be created with read access.
    read: bool = false,

    /// If the file already exists, and is a regular file, and the access
    /// mode allows writing, it will be truncated to length 0.
    truncate: bool = true,

    /// Ensures that this open call creates the file, otherwise causes
    /// `error.PathAlreadyExists` to be returned.
    exclusive: bool = false,

    /// For POSIX systems this is the file system mode the file will
    /// be created with. On other systems this is always 0.
    mode: Mode = default_mode,
};

const efs2 = @import("../efs2.zig");
const File = @This();
