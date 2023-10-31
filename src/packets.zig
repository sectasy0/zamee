const utils = @import("utils.zig");
const std = @import("std");

// Wake on Lan (WoL) packet.
pub const MagicPacket = extern struct {
    sync: [6]u8 = [6]u8{ 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF },
    payload: [96]u8 = undefined,

    pub fn init(dest_mac: []const u8) !MagicPacket {
        const cleaned: [12]u8 = utils.clean_addr(dest_mac)[0..12].*;

        var decoded: [6]u8 = undefined;
        _ = try std.fmt.hexToBytes(&decoded, &cleaned);

        return MagicPacket{ .payload = decoded ** 16 };
    }
};

test "MagicPacket initialization" {
    const result = try MagicPacket.init(@constCast("00:1A:2B:3C:4D:5E"));

    var decoded: [6]u8 = undefined;
    _ = try std.fmt.hexToBytes(&decoded, "001A2B3C4D5E");

    try std.testing.expectEqual(result.sync, [6]u8{ 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF });
    try std.testing.expectEqual(result.payload, decoded ** 16);
}
