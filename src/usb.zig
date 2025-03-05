const std = @import("std");
const io = std.io;
const mem = std.mem;
const c = @import("c");
const builtin = @import("builtin");
const hdlc = @import("hdlc.zig");
const usb = @This();

const timeout = 50;

pub const Context = struct {
    ctx: ?*c.libusb_context = null,

    pub fn init() !Context {
        var ctx: Context = .{};
        if (c.libusb_init(&ctx.ctx) < 0) return error.InitFailed;
        _ = c.libusb_set_option(
            ctx.ctx,
            c.LIBUSB_OPTION_LOG_LEVEL,
            c.LIBUSB_LOG_LEVEL_NONE,
        );
        var tv = c.timeval{ .tv_sec = 0, .tv_usec = timeout };
        _ = c.libusb_handle_events_timeout(ctx.ctx, &tv);
        return ctx;
    }

    pub fn deinit(self: Context) void {
        c.libusb_exit(self.ctx);
    }
};

pub const DevFinderRule = struct {
    bInterfaceClass: u8,
    bInterfaceSubClass: u8,
    bInterfaceProtocol: u8,
    bNumEndpoints: u8,
};

const dev_finder_rules = [_]DevFinderRule{
    .{
        .bInterfaceClass = 255,
        .bInterfaceSubClass = 255,
        .bInterfaceProtocol = 48,
        .bNumEndpoints = 2,
    },
    .{
        .bInterfaceClass = 255,
        .bInterfaceSubClass = 255,
        .bInterfaceProtocol = 255,
        .bNumEndpoints = 2,
    },
};

pub const Interface = struct {
    dev: ?*c.libusb_device = null,
    handle: ?*c.libusb_device_handle = null,
    configuration_value: c_int = -1,
    interface_number: c_int = -1,
    read_endpoint: u8 = 0,
    write_endpoint: u8 = 0,
    max_packet_size: usize = 0x200,
    received_first_packet: bool = false,

    pub fn autoFind() !Interface {
        var devs: [*c]?*c.libusb_device = null;
        const cnt = c.libusb_get_device_list(null, &devs);
        if (cnt < 0) {
            return error.NoUsbDeviceFound;
        }
        defer c.libusb_free_device_list(devs, 1);

        var i: usize = 0;
        outer: while (i < cnt) : (i += 1) {
            const dev = devs[i];
            var desc: c.libusb_device_descriptor = .{};
            if (c.libusb_get_device_descriptor(dev, &desc) < 0) {
                continue :outer;
            }

            var config: [*c]c.libusb_config_descriptor = null;
            if (c.libusb_get_active_config_descriptor(dev, &config) < 0) {
                continue :outer;
            }
            defer c.libusb_free_config_descriptor(config);

            var intf_idx: usize = 0;
            while (intf_idx < config.*.bNumInterfaces) : (intf_idx += 1) {
                const intf = &config.*.interface[intf_idx];
                var alt_idx: usize = 0;
                while (alt_idx < intf.*.num_altsetting) : (alt_idx += 1) {
                    const alt = &intf.altsetting[alt_idx];
                    for (dev_finder_rules) |rule| {
                        if (alt.*.bInterfaceClass == rule.bInterfaceClass and
                            alt.*.bInterfaceSubClass == rule.bInterfaceSubClass and
                            alt.*.bInterfaceProtocol == rule.bInterfaceProtocol and
                            alt.*.bNumEndpoints == rule.bNumEndpoints)
                        {
                            var iface: Interface = .{};
                            iface.dev = dev;
                            if (c.libusb_open(dev, &iface.handle) < 0) {
                                continue :outer;
                            }
                            iface.configuration_value = config.*.bConfigurationValue;
                            iface.interface_number = alt.*.bInterfaceNumber;
                            var j: usize = 0;
                            while (j < alt.*.bNumEndpoints) : (j += 1) {
                                const ep = &alt.*.endpoint[j];
                                iface.max_packet_size = @min(ep.*.wMaxPacketSize, iface.max_packet_size);
                                if (ep.*.bEndpointAddress & c.LIBUSB_ENDPOINT_DIR_MASK == c.LIBUSB_ENDPOINT_IN) {
                                    iface.read_endpoint = ep.*.bEndpointAddress;
                                } else if (ep.*.bEndpointAddress & c.LIBUSB_ENDPOINT_DIR_MASK == c.LIBUSB_ENDPOINT_OUT) {
                                    iface.write_endpoint = ep.*.bEndpointAddress;
                                }
                            }
                            try iface.claim();
                            return iface;
                        }
                    }
                }
            }
        }
        return error.NotFound;
    }

    pub const ClaimError = error{
        DetachKernelDriverFailed,
        SetConfigurationFailed,
        ClaimInterfaceFailed,
    };

    pub fn claim(self: *Interface) ClaimError!void {
        if (c.libusb_kernel_driver_active(self.handle, self.interface_number) == 1) {
            if (c.libusb_detach_kernel_driver(self.handle, self.interface_number) != 0) {
                return error.DetachKernelDriverFailed;
            }
        }

        if (builtin.os.tag == .windows and
            c.libusb_set_configuration(self.handle, self.configuration_value) < 0)
        {
            return error.SetConfigurationFailed;
        }

        if (c.libusb_claim_interface(self.handle, self.interface_number) < 0) {
            return error.ClaimInterfaceFailed;
        }
    }

    pub const ReadError = error{
        InvalidArgument,
        BrokenPipe,
        NoDevice,
        InputOutput,
        UnexpectedError,
    };

    pub const WriteError = error{
        InvalidArgument,
        BrokenPipe,
        NoDevice,
        InputOutput,
        UnexpectedError,
    } || mem.Allocator.Error;

    pub const Reader = io.Reader(Interface, ReadError, read);
    pub const Writer = io.Writer(Interface, WriteError, write);

    pub fn reader(self: Interface) Reader {
        return .{ .context = self };
    }

    pub fn writer(self: Interface) Writer {
        return .{ .context = self };
    }

    pub fn write(self: Interface, buf: []const u8) !usize {
        var amt: c_int = 0;
        const ret = c.libusb_bulk_transfer(
            self.handle,
            self.write_endpoint,
            @constCast(buf.ptr),
            @intCast(buf.len),
            &amt,
            timeout,
        );
        return blk: switch (ret) {
            c.LIBUSB_SUCCESS,
            c.LIBUSB_ERROR_TIMEOUT,
            c.LIBUSB_ERROR_OVERFLOW,
            => @intCast(amt),
            c.LIBUSB_ERROR_IO => error.InputOutput,
            c.LIBUSB_ERROR_PIPE => {
                _ = c.libusb_clear_halt(self.handle, self.write_endpoint);
                break :blk error.BrokenPipe;
            },
            c.LIBUSB_ERROR_NO_DEVICE => error.NoDevice,
            c.LIBUSB_ERROR_INVALID_PARAM => error.InvalidArgument,
            else => return error.UnexpectedError,
        };
    }

    pub fn read(self: Interface, buf: []u8) !usize {
        var amt: c_int = 0;
        const ret = c.libusb_bulk_transfer(
            self.handle,
            self.read_endpoint,
            @constCast(buf.ptr),
            @intCast(buf.len),
            &amt,
            0x7fffffff,
        );
        return blk: switch (ret) {
            c.LIBUSB_SUCCESS,
            c.LIBUSB_ERROR_TIMEOUT,
            c.LIBUSB_ERROR_OVERFLOW,
            => @intCast(amt),
            c.LIBUSB_ERROR_IO => error.InputOutput,
            c.LIBUSB_ERROR_PIPE => {
                _ = c.libusb_clear_halt(self.handle, self.read_endpoint);
                break :blk error.BrokenPipe;
            },
            c.LIBUSB_ERROR_NO_DEVICE => error.NoDevice,
            c.LIBUSB_ERROR_INVALID_PARAM => error.InvalidArgument,
            else => return error.UnexpectedError,
        };
    }

    pub fn deinit(self: Interface) void {
        defer if (self.handle) |h| {
            _ = c.libusb_release_interface(h, self.interface_number);
            c.libusb_close(h);
        };
    }
};

test {
    var ctx = try Context.init();
    defer ctx.deinit();
    var iface = try Interface.autoFind();
    defer iface.deinit();
}
