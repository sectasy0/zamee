const std = @import("std");
const os = @import("std").os;
const fmt = @import("std").fmt;

const utils = @import("utils.zig");
const net = @import("packets.zig");

fn show_help() !void {
    const stdout = std.io.getStdOut().writer();
    const help_text: []const u8 =
        \\Usage: zamee [OPTIONS]
        \\
        \\Description:
        \\  A command-line tool that allows you to remotely wake up your computer using Wake On Lan (WoL).
        \\
        \\Options:
        \\  -w, --wake       Wake up the target device (physical address).
        \\  -b, --bcast      Set the broadcast address for sending the magic packet (default: 255.255.255.255).
        \\  -p, --port       Specify the port to use for WoL (default: 9).
        \\  -h, --help       Display this help message and exit.
        \\  -v, --version    Display the tool's version and exit.
        \\
        \\Examples:
        \\  wake up - zamup -w 70-85-C2-9D-41-70 -p 9 -b 192.168.0.255
        \\
        \\Error Codes:
        \\  1 - Invalid arguments specified.
        \\  2 - Invalid physical address format.
        \\  3 - Failed to create or send the WoL payload.
        \\  4 - Invalid IPv4 broadcast address format.
        \\
    ;
    try stdout.print("{s}\n", .{help_text});
}

fn wake_up(packet: net.MagicPacket, addr: u32, port: u16) !void {
    const fd = try os.socket(os.AF.INET, os.SOCK.DGRAM, 0);
    defer os.closeSocket(fd);

    const bcast_opt = &std.mem.toBytes(@as(c_int, 1));
    _ = try os.setsockopt(fd, os.SOL.SOCKET, os.SO.BROADCAST, bcast_opt);

    const dest_addr_in = os.sockaddr.in{
        .family = os.AF.INET,
        .port = std.mem.bigToNative(u16, port),
        .addr = addr,
    };

    _ = try os.bind(fd, @ptrCast(&utils.create_source(port)), @sizeOf(os.sockaddr.in));

    const stream = &std.mem.asBytes(&packet);

    _ = try os.sendto(
        fd,
        stream.*,
        0,
        @ptrCast(&dest_addr_in),
        @sizeOf(os.sockaddr.in),
    );
}

fn handle_argument(arg: []const u8, args: [][:0]u8, i: u64) !u8 {
    if (std.mem.eql(u8, arg, "-w") or std.mem.eql(u8, arg, "--wake")) {
        const value: []const u8 = utils.get_value(args, i) catch {
            try show_help();
            return 1;
        };

        // physical address validation
        if (utils.validate_physical(value)) {
            const packet: net.MagicPacket = net.MagicPacket.init(value) catch {
                return 3;
            };

            var addr: []const u8 = "255.255.255.255";
            var port: u16 = 9;

            // get broadcast address as additional argument for -w command.
            // if not specified, just default.
            var result = utils.additional_argument(args, "-b", "-bcast");
            switch (result) {
                utils.ArgumentResult.ok => addr = result.ok.arg,
                utils.ArgumentResult.err => {
                    switch (result.err) {
                        // when argument wasn't specified i wanna argument to stay default.
                        utils.ArgumentError.InvalidArgument => {},
                        // show help if specified and missing.
                        utils.ArgumentError.ValueMissing => {
                            try show_help();
                            return 1;
                        },
                    }
                },
            }

            // get port as additional argument for -w command.
            // if not specified, just default.
            result = utils.additional_argument(args, "-p", "-port");
            switch (result) {
                // additional port validations.
                utils.ArgumentResult.ok => {
                    const presult: utils.PortResult = utils.parse_port(result.ok.arg);
                    switch (presult) {
                        utils.PortResult.ok => port = presult.ok.port,
                        utils.PortResult.err => {
                            try show_help();
                            return 1;
                        },
                    }
                },
                // aforementioned
                utils.ArgumentResult.err => {
                    switch (result.err) {
                        utils.ArgumentError.InvalidArgument => {},
                        utils.ArgumentError.ValueMissing => {
                            try show_help();
                            return 1;
                        },
                    }
                },
            }

            // convert addr to u32, also serves as ipv4 address validation
            const addr_u32: u32 = utils.inet2u32(addr) catch {
                return 4;
            };

            wake_up(packet, addr_u32, port) catch {
                return 3;
            };
        } else {
            return 2;
        }

        return 0;
    }

    if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
        try show_help();
        return 0;
    }

    if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("{s} v{s}\n", .{ "zamee", "0.0.1" });

        return 0;
    }

    // when passed no arguments aka default option.
    try show_help();
    return 1;
}

pub fn main() !u8 {
    const args: [][:0]u8 = try std.process.argsAlloc(std.heap.page_allocator);

    for (args, 0..) |arg, index| {
        if (index & 1 == 0) continue;

        return handle_argument(arg, args, index);
    }

    try show_help();
    return 1;
}
