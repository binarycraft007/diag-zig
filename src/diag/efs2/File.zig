/// The OS-specific file descriptor or file handle.
handle: Handle,

pub const Handle = efs2.fd_t;

pub fn open() !File {}

const File = @This();
const std = @import("std");
const efs2 = @import("../efs2.zig");
const diag = @import("../../diag.zig");
