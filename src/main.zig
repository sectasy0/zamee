const std = @import("std");
const os = @import("std").os;
const fmt = @import("std").fmt;

const utils = @import("utils.zig");
const net = @import("packets.zig");

const ExitCodes = enum(u8) {
    SUCCESS = 0,
    INVALID_ARGUMENT = 1,
    INVALID_PHYSICAL_ADDR = 2,
    PACKET_CREATE_FAILURE = 3,
    PACKET_SEND_FAILURE = 4,
    INVALID_INET4_ADDR = 5,
    STDOUT_FAILURE = 6,
    ARGUMENT_ALLOC_FAILURE = 7,
};

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
        \\  4 - Failed to send the WoL payload.
        \\  5 - Invalid IPv4 broadcast address format.
        \\  6 - Stdout failed while printing.
        \\  7 - Argument allocator failed.
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

fn handle_argument(arg: []const u8, args: [][:0]u8, i: u64) u8 {
    if (std.mem.eql(u8, arg, "-w") or std.mem.eql(u8, arg, "--wake")) {
        const value: []const u8 = utils.get_value(args, i) catch {
            show_help() catch {
                return @intFromEnum(ExitCodes.STDOUT_FAILURE);
            };
            return @intFromEnum(ExitCodes.INVALID_ARGUMENT);
        };

        // physical address validation
        if (utils.validate_physical(value)) {
            const packet: net.MagicPacket = net.MagicPacket.init(value) catch {
                return @intFromEnum(ExitCodes.PACKET_CREATE_FAILURE);
            };

            var addr: []const u8 = "255.255.255.255";
            var port: u16 = 9;

            // get broadcast address as additional argument for -w command.
            // if not specified, just default.
            var result = utils.additional_argument(args, "-b", "-bcast");
            switch (result) {
                .ok => addr = result.ok.arg,
                .err => {
                    switch (result.err) {
                        // when argument wasn't specified i wanna argument to stay default.
                        utils.ArgumentError.InvalidArgument => {},
                        // show help if specified and missing.
                        utils.ArgumentError.ValueMissing => {
                            show_help() catch {
                                return @intFromEnum(ExitCodes.STDOUT_FAILURE);
                            };
                            return @intFromEnum(ExitCodes.INVALID_ARGUMENT);
                        },
                    }
                },
            }

            // get port as additional argument for -w command.
            // if not specified, just default.
            result = utils.additional_argument(args, "-p", "-port");
            switch (result) {
                // additional port validations.
                .ok => {
                    const presult: utils.PortResult = utils.parse_port(result.ok.arg);
                    switch (presult) {
                        utils.PortResult.ok => port = presult.ok.port,
                        utils.PortResult.err => {
                            show_help() catch {
                                return @intFromEnum(ExitCodes.STDOUT_FAILURE);
                            };
                            return @intFromEnum(ExitCodes.INVALID_ARGUMENT);
                        },
                    }
                },
                // aforementioned
                .err => {
                    switch (result.err) {
                        utils.ArgumentError.InvalidArgument => {},
                        utils.ArgumentError.ValueMissing => {
                            show_help() catch {
                                return @intFromEnum(ExitCodes.STDOUT_FAILURE);
                            };
                            return @intFromEnum(ExitCodes.INVALID_ARGUMENT);
                        },
                    }
                },
            }

            // convert addr to u32, also serves as ipv4 address validation
            const addr_u32: u32 = utils.inet2u32(addr) catch {
                return @intFromEnum(ExitCodes.INVALID_INET4_ADDR);
            };

            wake_up(packet, addr_u32, port) catch {
                return @intFromEnum(ExitCodes.PACKET_SEND_FAILURE);
            };
        } else {
            return @intFromEnum(ExitCodes.INVALID_PHYSICAL_ADDR);
        }

        return @intFromEnum(ExitCodes.SUCCESS);
    }

    if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
        show_help() catch {
            return @intFromEnum(ExitCodes.STDOUT_FAILURE);
        };
        return @intFromEnum(ExitCodes.SUCCESS);
    }

    if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
        const stdout = std.io.getStdOut().writer();
        stdout.print("{s} v{s}\n", .{ "zamee", "0.0.1" }) catch {
            return @intFromEnum(ExitCodes.STDOUT_FAILURE);
        };

        return @intFromEnum(ExitCodes.SUCCESS);
    }

    // when passed no arguments aka default option.
    show_help() catch {
        return @intFromEnum(ExitCodes.STDOUT_FAILURE);
    };
    return @intFromEnum(ExitCodes.INVALID_ARGUMENT);
}

pub fn main() u8 {
    const alloc: std.mem.Allocator = std.heap.page_allocator;
    const args: [][:0]u8 = std.process.argsAlloc(alloc) catch {
        return @intFromEnum(ExitCodes.ARGUMENT_ALLOC_FAILURE);
    };

    defer std.process.argsFree(alloc, args);

    for (args, 0..) |arg, index| {
        // skip `odd` value cause is argument value which i'm getting later in `get_value`.
        if (index & 1 == 0) continue;

        return handle_argument(arg, args, index);
    }

    show_help();
    return @intFromEnum(ExitCodes.INVALID_ARGUMENT);
}
