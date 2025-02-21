const std = @import("std");
const c = @import("c");
const builtin = @import("builtin");
const usb = @This();

pub fn init() !void {
    if (c.libusb_init(null) < 0)
        return error.InitFailed;
}

pub fn deinit() void {
    c.libusb_exit(null);
}

pub const DevFinderRule = struct {
    bInterfaceClass: u8,
    bInterfaceSubClass: u8,
    bInterfaceProtocol: u8,
    bNumEndpoints: u8,
};

const dev_finder_rules = [_]DevFinderRule{
    .{ .bInterfaceClass = 255, .bInterfaceSubClass = 255, .bInterfaceProtocol = 48, .bNumEndpoints = 2 },
    .{ .bInterfaceClass = 255, .bInterfaceSubClass = 255, .bInterfaceProtocol = 255, .bNumEndpoints = 2 },
};

pub const Interface = struct {
    dev: ?*c.libusb_device = null,
    handle: ?*c.libusb_device_handle = null,
    configuration_value: c_int = -1,
    interface_number: c_int = -1,
    read_endpoint: u8 = 0,
    write_endpoint: u8 = 0,
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
                                if (ep.*.bEndpointAddress & c.LIBUSB_ENDPOINT_DIR_MASK == c.LIBUSB_ENDPOINT_IN) {
                                    iface.read_endpoint = ep.*.bEndpointAddress;
                                } else if (ep.*.bEndpointAddress & c.LIBUSB_ENDPOINT_DIR_MASK == c.LIBUSB_ENDPOINT_OUT) {
                                    iface.write_endpoint = ep.*.bEndpointAddress;
                                }
                                try iface.claim();
                                return iface;
                            }
                        }
                    }
                }
            }
        }
        return error.NotFound;
    }

    pub fn claim(self: *Interface) !void {
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

    pub fn write(self: *Interface, buf: []const u8) !usize {
        var amt: c_int = 0;
        if (c.libusb_bulk_transfer(
            self.handle,
            self.write_endpoint,
            @constCast(buf.ptr),
            @intCast(buf.len),
            &amt,
            1000,
        ) < 0) {
            return error.BulkTransferFailed;
        }
        return @intCast(amt);
    }

    pub fn deinit(self: *Interface) void {
        defer if (self.handle) |h| {
            _ = c.libusb_release_interface(h, self.interface_number);
            c.libusb_close(h);
        };
    }
};

test {
    try init();
    defer deinit();
    var iface = try Interface.autoFind();
    defer iface.deinit();
}
