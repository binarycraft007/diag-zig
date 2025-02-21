const std = @import("std");
const c = @import("c");
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
    .{ 255, 255, 48, 2 },
    .{ 255, 255, 255, 2 },
};

pub const Interface = struct {
    dev: ?*c.libusb_device,
    handle: ?*c.libusb_device_handle,
    configuration_value: c_int,
    interface_number: c_int,
    read_endpoint: u8,
    write_endpoint: u8,

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
                            var iface: Interface = undefined;
                            iface.dev = dev;
                            if (c.libusb_open(dev, &iface.handle) < 0) {
                                continue;
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
                                return iface;
                            }
                        }
                    }
                }
            }
        }
        return error.NotFound;
    }
};
