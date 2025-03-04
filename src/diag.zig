const std = @import("std");
const mem = std.mem;
const hdlc = @import("hdlc.zig");

pub const efs2 = @import("diag/efs2.zig");

pub const Subsys = enum(u8) {
    pub const Header = packed struct {
        cmd_code: u8,
        subsys_id: u8,
        subsys_cmd_code: u16,
    };

    pub const nv_read_ext_f = 1; // NV ext subsys command for NV-item read
    pub const nv_write_ext_f = 2; // NV ext subsys command for NV-item write

    oem = 0,
    zrex = 1,
    sd = 2,
    bt = 3,
    wcdma = 4,
    hdr = 5,
    diablo = 6,
    trex = 7,
    gsm = 8,
    umts = 9,
    hwtc = 10,
    ftm = 11,
    //rex = 12,
    os = 12, // diag_subsys_os is equal to diag_subsys_rex
    gps = 13,
    wms = 14,
    cm = 15,
    hs = 16,
    audio_settings = 17,
    diag_serv = 18,
    fs = 19,
    port_map_settings = 20,
    mediaplayer = 21,
    qcamera = 22,
    mobimon = 23,
    gunimon = 24,
    lsm = 25,
    qcamcorder = 26,
    mux1x = 27,
    data1x = 28,
    srch1x = 29,
    callp1x = 30,
    apps = 31,
    settings = 32,
    //gsdi = 33,
    uimdiag = 33, // diag_subsys_uimdiag is equal to diag_subsys_gsdi
    tmc = 34,
    usb = 35,
    pm = 36,
    debug = 37,
    qtv = 38,
    clkrgm = 39,
    devices = 40,
    wlan = 41,
    //ps_data_logging = 42,
    ps = 42, // diag_subsys_ps is equal to diag_subsys_ps_data_logging
    mflo = 43,
    dtv = 44,
    rrc = 45,
    prof = 46,
    tcxomgr = 47,
    nv = 48,
    autoconfig = 49,
    params = 50,
    mddi = 51,
    ds_atcop = 52,
    l4linux = 53,
    mvs = 54,
    cnv = 55,
    apione_program = 56,
    hit = 57,
    drm = 58,
    dm = 59,
    fc = 60,
    memory = 61,
    fs_alternate = 62,
    regression = 63,
    sensors = 64,
    flute = 65,
    analog = 66,
    apione_program_modem = 67,
    lte = 68,
    brew = 69,
    pwrdb = 70,
    chord = 71,
    sec = 72,
    time = 73,
    q6_core = 74,
    corebsp = 75,
    mflo2 = 76,
    ulog = 77,
    apr = 78,
    qnp = 79,
    stride = 80,
    oemdpp = 81,
    q5_core = 82,
    uscript = 83,
    nas = 84,
    cmapi = 85,
    ssm = 86,
    tdscdma = 87,
    ssm_test = 88,
    mpower = 89,
    qdss = 90,
    cxm = 91,
    gnss_soc = 92,
    ttlite = 93,
    ftm_ant = 94,
    mlog = 95,
    limitsmgr = 96,
    efsmonitor = 97,
    display_calibration = 98,
    version_report = 99,
    ds_ipa = 100,
    system_operations = 101,
    cnss_power = 102,
    lwip = 103,
    ims_qvp_rtp = 104,
    storage = 105,
    wci2 = 106,
    aostlm_test = 107,
    cfcm = 108,
    core_services = 109,
    cvd = 110,
    mcfg = 111,
    modem_stressfw = 112,
    ds_ds3g = 113,
    trm = 114,
    ims = 115,
    ota_firewall = 116,
    i15p4 = 117,
    qdr = 118,
    mcs = 119,
    modemfw = 120,
    qnad = 121,
    f_reserved = 122,
    v2x = 123,
    qmesa = 124,
    sleep = 125,
    quest = 126,
    cdsp_qmesa = 127,
    pcie = 128,
    qdsp_stress_test = 129,
    chargerpd = 130,
    last = 131,
    reserved_oem_0 = 250,
    reserved_oem_1 = 251,
    reserved_oem_2 = 252,
    reserved_oem_3 = 253,
    reserved_oem_4 = 254,
    legacy = 255,
};

pub const Command = enum(u8) {
    verno_f = 0,
    esn_f = 1,
    peekb_f = 2,
    peekw_f = 3,
    peekd_f = 4,
    pokeb_f = 5,
    pokew_f = 6,
    poked_f = 7,
    outp_f = 8,
    outpw_f = 9,
    inp_f = 10,
    inpw_f = 11,
    status_f = 12,
    logmask_f = 15,
    log_f = 16,
    nv_peek_f = 17,
    nv_poke_f = 18,
    bad_cmd_f = 19,
    bad_parm_f = 20,
    bad_len_f = 21,
    bad_mode_f = 24,
    tagraph_f = 25,
    markov_f = 26,
    markov_reset_f = 27,
    diag_ver_f = 28,
    ts_f = 29,
    ta_parm_f = 30,
    msg_f = 31,
    hs_key_f = 32,
    hs_lock_f = 33,
    hs_screen_f = 34,
    parm_set_f = 36,
    nv_read_f = 38,
    nv_write_f = 39,
    control_f = 41,
    err_read_f = 42,
    err_clear_f = 43,
    ser_reset_f = 44,
    ser_report_f = 45,
    test_f = 46,
    get_dipsw_f = 47,
    set_dipsw_f = 48,
    voc_pcm_lb_f = 49,
    voc_pkt_lb_f = 50,
    orig_f = 53,
    end_f = 54,
    sw_version_f = 56,
    dload_f = 58,
    tmob_f = 59,
    //ftm_cmd_f = 59,
    ext_sw_version_f = 60,
    test_state_f = 61,
    state_f = 63,
    pilot_sets_f = 64,
    spc_f = 65,
    bad_spc_mode_f = 66,
    parm_get2_f = 67,
    serial_chg_f = 68,
    password_f = 70,
    bad_sec_mode_f = 71,
    pr_list_wr_f = 72,
    pr_list_rd_f = 73,
    subsys_cmd_f = 75,
    feature_query_f = 81,
    sms_read_f = 83,
    sms_write_f = 84,
    sup_fer_f = 85,
    sup_walsh_codes_f = 86,
    set_max_sup_ch_f = 87,
    parm_get_is95b_f = 88,
    fs_op_f = 89,
    akey_verify_f = 90,
    bmp_hs_screen_f = 91,
    config_comm_f = 92,
    ext_logmask_f = 93,
    event_report_f = 96,
    streaming_config_f = 97,
    parm_retrieve_f = 98,
    status_snapshot_f = 99,
    rpc_f = 100,
    get_property_f = 101,
    put_property_f = 102,
    get_guid_f = 103,
    user_cmd_f = 104,
    get_perm_property_f = 105,
    put_perm_property_f = 106,
    perm_user_cmd_f = 107,
    gps_sess_ctrl_f = 108,
    gps_grid_f = 109,
    gps_statistics_f = 110,
    route_f = 111,
    is2000_status_f = 112,
    rlp_stat_reset_f = 113,
    tdso_stat_reset_f = 114,
    log_config_f = 115,
    trace_event_report_f = 116,
    sbi_read_f = 117,
    sbi_write_f = 118,
    ssd_verify_f = 119,
    log_on_demand_f = 120,
    ext_msg_f = 121,
    oncrpc_f = 122,
    protocol_loopback_f = 123,
    ext_build_id_f = 124,
    ext_msg_config_f = 125,
    ext_msg_terse_f = 126,
    ext_msg_terse_xlate_f = 127,
    subsys_cmd_ver_2_f = 128,
    event_mask_get_f = 129,
    event_mask_set_f = 130,
    change_port_settings_f = 140,
    cntry_info_f = 141,
    sups_req_f = 142,
    mms_orig_sms_request_f = 143,
    meas_mode_f = 144,
    meas_req_f = 145,
    qsr_ext_msg_terse_f = 146,
    dci_cmd_req_f = 147,
    dci_delayed_rsp_f = 148,
    bad_trans_f = 149,
    ssm_disallowed_cmd_f = 150,
    log_on_demand_ext_f = 151,
    multi_radio_cmd_f = 152,
    qsr4_ext_msg_terse_f = 153,
    dci_control_packet = 154,
    compressed_pkt = 155,
    msg_small_f = 156,
    qsh_trace_payload_f = 157,
    //max_f = 157,
};

pub const Mode = enum(u8) {
    offline_a_f = 0, // Go to offline analog
    offline_d_f, // Go to offline digital
    reset_f, // Reset. Only exit from offline
    ftm_f, // FTM mode - if supported
    online_f, // Online mode - if supported
    lpm_f, // LPM mode - if supported
    power_off_f, // Power off mode
    camp_only_f, // Camp Only Mode
    sdrm_f, // SDRM mode
    max_f, // Last (and invalid) mode enum value
};

pub const Control = struct {
    request: Request = .{},
    response: Response = .{},

    pub const Request = packed struct {
        const Self = @This();

        pub const diag_cm_reset = 2;
        pub const diag_cm_power_off = 6;

        pub const Header = packed struct {
            cmd_code: u8 = @intFromEnum(Command.control_f),
        };
        header: Header = .{},
        mode: Mode = .offline_a_f,
        reserved: u8 = 0x00,
    };

    pub const Response = Request;
};

pub const SystemOperations = struct {
    request: Request = .{},
    response: Response = .{},

    pub const Request = packed struct {
        const Self = @This();
        const edl_reset_cmd_code = 1;
        pub const size = @sizeOf(Self);

        header: Subsys.Header = .{
            .cmd_code = @intFromEnum(Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(Subsys.system_operations),
            .subsys_cmd_code = edl_reset_cmd_code,
        },
    };

    pub const Response = Request;
};

pub const Loopback = struct {
    request: Request = .{},
    response: Response = .{},

    pub const Request = packed struct {
        const Self = @This();

        pub const Header = packed struct {
            cmd_code: u8 = @intFromEnum(Command.protocol_loopback_f),
        };
        header: Header = .{},
        data0: u8 = 0x00,
        data1: u8 = 0x01,
        data2: u8 = 0x02,
        data3: u8 = 0x03,
        data4: u8 = 0x04,
        data5: u8 = 0x05,
        data6: u8 = 0x06,
        data7: u8 = 0x07,
        data8: u8 = 0x08,
        data9: u8 = 0x09,
    };

    pub const Response = Request;
};

pub const VersionInfo = struct {
    pub const date_strlen = 11;
    pub const time_strlen = 8;
    pub const dir_strlen = 8;

    request: Request = .{},
    response: Response = undefined,

    pub const Header = packed struct {
        cmd_code: u8 = @intFromEnum(Command.verno_f),
    };

    pub const Request = packed struct {
        const Self = @This();

        header: Header = .{},
    };

    pub const Response = extern struct {
        const Self = @This();

        header: Header align(1) = .{},

        comp_date: [date_strlen]u8 align(1), // Compile date Jun 11 1991
        comp_time: [time_strlen]u8 align(1), // Compile time hh:mm:ss
        rel_date: [date_strlen]u8 align(1), // Release date
        rel_time: [time_strlen]u8 align(1), // Release time
        ver_dir: [dir_strlen]u8 align(1), // Version directory
        scm: u8 align(1), // Station Class Mark
        mob_cai_rev: u8 align(1), // CAI rev
        mob_model: u8 align(1), // Mobile Model
        mob_firm_rev: u16 align(1), // Firmware Rev
        slot_cycle_index: u8 align(1), // Slot Cycle Index
        hw_maj_ver: u8 align(1), // Hardware Version MSB
        hw_min_ver: u8 align(1), // Hardware Version LSB
    };
};

pub const ServiceProgramming = struct {
    request: Request = .{},
    response: Response = .{},

    pub const ServiceCode = packed struct {
        digit0: u8 = 0x30,
        digit1: u8 = 0x30,
        digit2: u8 = 0x30,
        digit3: u8 = 0x30,
        digit4: u8 = 0x30,
        digit5: u8 = 0x30,
    };

    pub const Header = packed struct {
        cmd_code: u8 = @intFromEnum(Command.spc_f),
    };

    pub const Request = packed struct {
        const Self = @This();

        header: Header = .{},
        sec_code: ServiceCode = .{},
    };

    pub const Response = packed struct {
        const Self = @This();

        header: Header = .{},
        sec_code_ok: u8 = 0x00,
    };
};

pub const ExtBuildId = struct {
    request: Request = .{},
    response: Response = .{},

    pub const Header = packed struct {
        cmd_code: u8 = @intFromEnum(Command.ext_build_id_f),
    };

    pub const Request = packed struct {
        const Self = @This();

        header: Header = .{},
    };

    pub const Response = extern struct {
        const Self = @This();

        header: Header = .{},
        msm_hw_version_format: u8 = 0,
        reserved: [2]u8 = [_]u8{0} ** 2, // for alignment / future use

        msm_hw_version: u32 = 0,
        mobile_model_id: u32 = 0,

        // The following character array contains 2 NULL terminated strings:
        // 'build_id' string, followed by 'model_string'
        ver_strings: [1]u8 = undefined,
    };
};

pub const FeatureQuery = struct {
    request: Request = .{},
    response: Response = .{},

    const diag_feature_query = 0x225;
    pub const Request = packed struct {
        header: Subsys.Header = .{
            .cmd_code = @intFromEnum(Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(Subsys.diag_serv),
            .subsys_cmd_code = diag_feature_query,
        },
    };

    pub const Response = extern struct {
        header: Subsys.Header align(1) = undefined,
        version: u8 align(1) = 0,
        feature_len: u8 align(1) = 0,
        feature_mask: [4]u8 align(1) = [_]u8{0} ** 4,
    };
};

pub const NvStat = enum(u16) {
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

pub const NvReadExt = struct {
    const nv_item_size = 128;
    const max_nv_id = 0xffff;

    request: Request = .{ .item = max_nv_id },
    response: Response = .{ .item = max_nv_id },

    pub const Header = packed struct {
        cmd_code: u8 = @intFromEnum(Command.nv_read_f),
    };

    pub const Request = extern struct {
        const Self = @This();

        header: Subsys.Header align(1) = .{
            .cmd_code = @intFromEnum(Command.subsys_cmd_f),
            .subsys_id = @intFromEnum(Subsys.nv),
            .subsys_cmd_code = Subsys.nv_read_ext_f,
        },
        item: u16 align(1), // Which item - use nv_items_enum_type
        context: u16 align(1) = 0,
        item_data: [nv_item_size]u8 align(1) = [_]u8{0} ** nv_item_size, // Item itself - use nv_item_type
        nv_stat: NvStat align(1) = .done, // Status of operation - use nv_stat_enum_type
    };

    pub const Response = Request;
};

pub const NvRead = struct {
    const nv_item_size = 128;
    const max_nv_id = 0xffff;

    request: Request = .{ .item = max_nv_id },
    response: Response = .{ .item = max_nv_id },

    pub const Header = packed struct {
        cmd_code: u8 = @intFromEnum(Command.nv_read_f),
    };

    pub const Request = extern struct {
        const Self = @This();

        header: Header align(1) = .{},
        item: u16 align(1), // Which item - use nv_items_enum_type
        item_data: [nv_item_size]u8 align(1) = [_]u8{0} ** nv_item_size, // Item itself - use nv_item_type
        nv_stat: NvStat align(1) = .done, // Status of operation
    };

    pub const Response = Request;
};

pub fn sendAndRecv(comptime T: type, data: T.Request, gpa: mem.Allocator, driver: anytype) !T {
    var context: T = .{ .request = data };
    const req_size = dataSize(context.request);
    const rep_size = dataSize(context.response);

    var encoder: hdlc.Encoder = .{ .gpa = gpa };
    const req = try encoder.encode(mem.asBytes(&context.request)[0..req_size]);
    defer gpa.free(req);

    try driver.writer().writeAll(req);

    var decoder = hdlc.Decoder.init(gpa);
    defer decoder.deinit();
    const header_bytes = mem.asBytes(&context.request.header);
    while (decoder.state != .done) {
        var buf: [512]u8 = undefined;
        const amt = try driver.reader().read(&buf);
        if (decoder.state == .start) {
            const cmd: Command = @enumFromInt(buf[0]);
            switch (cmd) {
                .bad_cmd_f,
                .bad_mode_f,
                .bad_parm_f,
                .bad_len_f,
                => {
                    if (mem.eql(u8, buf[1..header_bytes.len], header_bytes)) {
                        return error.UnsupportCommand;
                    }
                },
                else => {},
            }
        }
        if (!mem.eql(u8, buf[0..header_bytes.len], header_bytes)) {
            continue;
        }
        try decoder.decode(buf[0..amt]);
    }

    const result = try decoder.result();
    defer gpa.free(result);
    @memcpy(mem.asBytes(&context.response)[0..rep_size], result[0..rep_size]);

    return context;
}

pub fn dataSize(data: anytype) usize {
    const DataType = @TypeOf(data);
    const fields = std.meta.fields(DataType);
    const last_field = fields[fields.len - 1];
    const last_field_size = @sizeOf(@TypeOf(@field(data, last_field.name)));
    const bit_size = last_field_size * 8 + @bitOffsetOf(DataType, last_field.name);
    return @min(@sizeOf(DataType), bit_size / 8);
}
