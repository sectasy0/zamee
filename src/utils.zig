const testing = @import("std").testing;
const std = @import("std");

/// Retrieves a value from a slice of byte slices at the specified index.
///
/// This function takes a slice of byte slices `args` and an `index` to access a specific
/// element within the slice. If the `index` is within bounds, the function returns the
/// byte slice at the `index + 1`. If the `index` is out of bounds, it returns an
/// `error.InvalidArgument`.
///
/// # Arguments
/// * `args` - A slice of byte slices containing the data to be accessed.
/// * `index` - The index specifying the element to retrieve within the `args` slice.
///
/// # Returns
/// A Result containing the byte slice at the specified index if successful, or an
/// error if the index is out of bounds.
pub fn get_value(args: []const [:0]const u8, index: usize) ![]const u8 {
    if (args.len <= index + 1) return error.ValueMissing;
    return args[index + 1];
}

test "get_value existing" {
    const args: []const [:0]const u8 = &.{
        "/home/user/.cache/zig/o/fbae78c4fd5bbf983752b5d644ad3814/main",
        "-w",
        "00-B0-D0-63-32-54",
        "-b",
        "255.255.255.255",
    };

    const expected: []const u8 = "00-B0-D0-63-32-54";
    const result = try get_value(args, 1);

    try testing.expectEqual(expected, result);
}

test "get_value arg value not passed" {
    const args: []const [:0]const u8 = &.{
        "/home/user/.cache/zig/o/fbae78c4fd5bbf983752b5d644ad3814/main",
        "-w",
    };
    const result = get_value(args, 1);
    try testing.expect(result == error.ValueMissing);
}

test "get_value empty args" {
    const args: []const [:0]const u8 = &.{};
    const result = get_value(args, 1);
    try testing.expect(result == error.ValueMissing);
}

/// Validates a physical (MAC) address represented as a string.
///
/// This function checks whether the provided physical address, given as a string, is valid.
/// A valid physical address should have a length of 17 characters, consisting of 12 hexadecimal
/// digits and 5 separators (either colons ':' or hyphens '-'). It also ensures that the separators
/// are consistently placed every two characters starting from the third character. Any other
/// characters are considered invalid.
///
/// # Parameters
/// - `mac`: The physical address as a string, e.g., "00:1A:2B:3C:4D:5E".
///
/// # Returns
/// `true` if the input string represents a valid physical address, `false` otherwise.
pub fn validate_physical(mac: []const u8) bool {
    if (mac.len != 17) return false;

    var separator: u8 = mac[2];

    for (mac, 0..) |byte, index| {
        if (index % 3 == 2) {
            if (byte != 58 and
                byte != 45)
            {
                return false;
            }
            if (index > 5 and mac[index - 3] != separator) {
                return false;
            }
        } else if (!std.ascii.isHex(byte)) {
            return false;
        }
    }

    return true;
}

test "validate_physical valid address" {
    const mac: []const u8 = "00:1A:2B:3C:4D:5E";
    const result = validate_physical(mac);
    try testing.expectEqual(result, true);
}

test "validate_physical valid lowercase" {
    const mac: []const u8 = "00:1a:2b:3c:4d:5e";
    const result = validate_physical(mac);
    try testing.expectEqual(result, true);
}

test "validate_physical valid address with hyphens" {
    const mac: []const u8 = "00-1A-2B-3C-4D-5E";
    const result = validate_physical(mac);
    try testing.expectEqual(result, true);
}

test "validate_physical invalid address with invalid characters" {
    const mac: []const u8 = "00:1A:2B:3C:4G:5E";
    const result = validate_physical(mac);
    try testing.expectEqual(result, false);
}

test "validate_physical invalid address with incorrect length" {
    const mac: []const u8 = "00:1A:2B:3C:4D:5";
    const result = validate_physical(mac);
    try testing.expectEqual(result, false);
}

test "validate_physical invalid address with incorrect separators" {
    const mac: []const u8 = "00!1A!2B!3C!4D!5E";
    const result = validate_physical(mac);
    try testing.expectEqual(result, false);
}

test "validate_physical invalid address with mixing separators" {
    const mac: []const u8 = "00-1A-2B:3C:4D:5E";
    const result = validate_physical(mac);
    try testing.expectEqual(result, false);
}

/// Cleans physical or logical address from separators.
///
/// This function takes address string (mac or inet), which may contain separators such as colons (':')
/// or hyphens ('-') or comas ('.') and removes those separators. The resulting ddress is returned as an
/// array of bytes (u8). The cleaned MAC address is aligned to the left in the
/// resulting array.
///
/// # Parameters
/// - `addr`: address as a string, e.g., "00:1A:2B:3C:4D:5E".
///
/// # Returns
/// An array representing the cleaned address
pub fn clean_addr(addr: []const u8) [12]u8 {
    var result: [12]u8 = undefined;
    var level: usize = 0;

    for (addr, 0..) |byte, index| {
        if (byte == 45 or byte == 58) {
            level = level + 1;
            continue;
        }
        result[index - level] = byte;
    }
    return result;
}

test "clean_mac address with colons" {
    const mac: []const u8 = "70:85:C2:9D:41:70";
    const expected = [12]u8{ 55, 48, 56, 53, 67, 50, 57, 68, 52, 49, 55, 48 };
    const result = clean_addr(mac);
    try testing.expectEqual(result, expected);
}

test "clean_mac address with hyphens" {
    const mac: []const u8 = "70-85-C2-9D-41-70";
    const expected = [12]u8{ 55, 48, 56, 53, 67, 50, 57, 68, 52, 49, 55, 48 };
    const result = clean_addr(mac);
    try testing.expectEqual(result, expected);
}

/// Creates a source address structure for an IPv4 (AF.INET) socket with the specified port.
///
/// This function constructs a `std.os.sockaddr.in` structure, which is commonly used for
/// defining source addresses for IPv4 socket operations. It initializes the `family` field
/// to `std.os.AF.INET`, sets the `port` field to the provided `port` value, and leaves the
/// `addr` field as 0.
///
/// # Parameters
/// - `port`: The port number to assign to the source address.
///
/// # Returns
/// A `std.os.sockaddr.in` structure representing the source address with the specified port.
pub fn create_source(port: u16) std.os.sockaddr.in {
    const src_addr_in = std.os.sockaddr.in{
        .family = std.os.AF.INET,
        .port = std.mem.bigToNative(u16, port),
        .addr = std.mem.bigToNative(u32, 0),
    };
    return src_addr_in;
}

test "create_source with port 9" {
    const port: u16 = 9;
    const expected = std.os.sockaddr.in{
        .family = std.os.AF.INET,
        .port = std.mem.bigToNative(u16, port),
        .addr = std.mem.bigToNative(u32, 0),
    };
    const result = create_source(port);
    try testing.expectEqual(result, expected);
}

/// Converts a byte slice representing an IP address into a 32-bit unsigned integer.
///
/// This function takes a byte slice `addr` representing an IP address and attempts to
/// resolve it into a 32-bit unsigned integer (IPv4 address). If successful, it returns
/// the 32-bit integer. If the address is IPv6, it returns an `error.InvalidAddress`. If
/// the address family is anything other than IPv4 or IPv6 (should be unreachable), it
/// triggers a panic.
///
/// # Arguments
/// * `addr` - A byte slice containing the IP address to be converted.
///
/// # Returns
/// A `Result` containing a 32-bit unsigned integer if successful, or an error if the
/// address is invalid.
pub fn inet2u32(addr: []const u8) !u32 {
    var addr_s = try std.net.Address.parseIp(addr, 0);
    const addr_u32: u32 = switch (addr_s.any.family) {
        std.os.AF.INET => addr_s.in.sa.addr,
        std.os.AF.INET6 => return error.InvalidAddress,
        else => unreachable,
    };
    return addr_u32;
}

test "inet2u32 valid inet4 address" {
    const result = try inet2u32(@constCast("192.168.0.1"));

    const expected: u32 = 16820416; // is in network order
    try testing.expectEqual(result, expected);
}

test "inet2u32 invalid inet6 address" {
    const result = inet2u32(@constCast("2001:0db8:85a3:0000:0000:8a2e:0370:7334"));

    try testing.expectError(error.InvalidAddress, result);
}

test "inet2u32 invalid address family" {
    const result = inet2u32(@constCast("1234.23.0.1"));

    try testing.expectError(error.InvalidIPAddressFormat, result);
}

test "inet2u32 another valid inet4 address" {
    const result = try inet2u32(@constCast("127.0.0.1"));

    const expected: u32 = 16777343;
    try testing.expectEqual(expected, result);
}

/// Searches for a specific argument within a byte slice and returns its value.
///
/// If the `short` or `long` argument is found in `args`, this function attempts
/// to retrieve and return its value. If no matching argument is found, it returns
/// `error.InvalidArgument`.
///
/// # Arguments
/// - `args`: Byte slice containing the arguments to search within.
/// - `short`: Short argument to search for.
/// - `long`: Long argument to search for.
///
/// # Returns
/// - ArgumentResult which represents `ok` and `value`
pub const ArgumentResult = union(enum) {
    ok: struct { arg: []const u8 },
    err: ArgumentError,
};
pub const ArgumentError = union(enum) {
    ValueMissing,
    InvalidArgument,
};
pub fn additional_argument(args: []const [:0]const u8, short: *const [2:0]u8, long: []const u8) ArgumentResult {
    for (args, 0..) |arg, index| {
        if (std.mem.eql(u8, arg, short) or std.mem.eql(u8, arg, long)) {
            const value = get_value(args, index) catch {
                return .{ .err = ArgumentError.ValueMissing };
            };

            return .{ .ok = .{ .arg = value } };
        }
    }

    return .{ .err = ArgumentError.InvalidArgument };
}

test "additional_argument ok for short" {
    // cli arguments mock
    const args: []const [:0]const u8 = &.{
        "/home/user/.cache/zig/o/fbae78c4fd5bbf983752b5d644ad3814/main",
        "-w",
        "00-B0-D0-63-32-54",
        "-b",
        "255.255.255.255",
    };

    const result = additional_argument(args, "-b", "--bcast");

    const arg: []const u8 = "255.255.255.255";
    const expected = ArgumentResult{ .ok = .{ .arg = arg } };

    try testing.expectEqual(expected, result);
}

test "additional_argument ok for long" {
    // cli arguments mock
    const args: []const [:0]const u8 = &.{
        "/home/user/.cache/zig/o/fbae78c4fd5bbf983752b5d644ad3814/main",
        "-w",
        "00-B0-D0-63-32-54",
        "--bcast",
        "255.255.255.255",
    };

    const result = additional_argument(args, "-b", "--bcast");

    const arg: []const u8 = "255.255.255.255";
    const expected = ArgumentResult{ .ok = .{ .arg = arg } };

    try testing.expectEqual(expected, result);
}

test "additional_argument err for long without value" {
    // cli arguments mock
    const args: []const [:0]const u8 = &.{
        "/home/user/.cache/zig/o/fbae78c4fd5bbf983752b5d644ad3814/main",
        "-w",
        "00-B0-D0-63-32-54",
        "--bcast",
    };

    const result = additional_argument(args, "-b", "--bcast");

    const expected = ArgumentResult{ .err = ArgumentError.ValueMissing };

    try testing.expectEqual(expected, result);
}

test "additional_argument err for long with one dash" {
    // cli arguments mock
    const args: []const [:0]const u8 = &.{
        "/home/user/.cache/zig/o/fbae78c4fd5bbf983752b5d644ad3814/main",
        "-w",
        "00-B0-D0-63-32-54",
        "-bcast",
        "255.255.255.255",
    };

    const result = additional_argument(args, "-b", "--bcast");

    const expected = ArgumentResult{ .err = ArgumentError.InvalidArgument };

    try testing.expectEqual(expected, result);
}

test "additional_argument err for specified but not passed" {
    // cli arguments mock
    const args: []const [:0]const u8 = &.{
        "/home/user/.cache/zig/o/fbae78c4fd5bbf983752b5d644ad3814/main",
        "-w",
        "00-B0-D0-63-32-54",
    };

    const result = additional_argument(args, "-b", "--bcast");

    const expected = ArgumentResult{ .err = ArgumentError.InvalidArgument };

    try testing.expectEqual(expected, result);
}

/// Parses a port number from a byte slice and returns the result.
///
/// This function takes a byte slice `port` containing characters that represent
/// a port number, attempts to parse it into a 16-bit unsigned integer (u16), and
/// returns the result in a `PortResult` union. If the parsing is successful, it
/// returns an `ok` variant containing the parsed port number. If the parsing
/// encounters an error, it returns an `err` variant with a specific `PortError`
/// enum to indicate the nature of the error.
///
/// # Arguments
/// - `port`: A byte slice containing characters representing a port number.
///
/// # Returns
/// - A `PortResult` union representing the parsing result.
pub const PortResult = union(enum) {
    ok: struct { port: u16 },
    err: PortError,
};
pub const PortError = union(enum) { InvalidPort };
pub fn parse_port(port: []const u8) PortResult {
    const result = std.fmt.parseInt(u16, port, 10) catch {
        return .{ .err = PortError.InvalidPort };
    };

    return .{ .ok = .{ .port = result } };
}

test "valid port" {
    try testing.expectEqual(.{ .port = 8080 }, parse_port(@constCast("8080")));
}

test "invalid character" {
    try testing.expectEqual(.{ .err = PortError.InvalidPort }, parse_port(@constCast("abc")));
}

test "empty input" {
    try testing.expectEqual(.{ .err = PortError.InvalidPort }, parse_port(@constCast("")));
}

test "Test overflow" {
    try testing.expectEqual(.{ .err = PortError.InvalidPort }, parse_port(@constCast("65536")));
}
