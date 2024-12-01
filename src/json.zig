const std = @import("std");
const types = @import("types.zig");

pub fn parseMarketData(allocator: std.mem.Allocator, json_data: []const u8, coin_id: []const u8) !types.CoinInfo {
    var json_value = try std.json.parseFromSlice(std.json.Value, allocator, json_data, .{});
    defer json_value.deinit();

    const root = json_value.value;
    if (root != .object) return error.InvalidResponse;

    const coin_data = root.object.get(coin_id) orelse return error.CoinNotFound;
    if (coin_data != .object) return error.InvalidResponse;

    const data = coin_data.object;

    // Helper to safely get values
    const getFloat = struct {
        fn get(obj: std.json.ObjectMap, key: []const u8) ?f64 {
            const val = obj.get(key) orelse return null;
            return switch (val) {
                .float => |f| f,
                .integer => |i| @floatFromInt(i),
                else => null,
            };
        }
    }.get;

    return types.CoinInfo{
        .id = try allocator.dupe(u8, coin_id),
        .symbol = try allocator.dupe(u8, coin_id),
        .name = try allocator.dupe(u8, coin_id),
        .current_price = getFloat(data, "usd") orelse 0,
        .market_cap = getFloat(data, "usd_market_cap") orelse 0,
        .market_cap_rank = null,
        .total_volume = getFloat(data, "usd_24h_vol") orelse 0,
        .high_24h = null,
        .low_24h = null,
        .price_change_24h = null,
        .price_change_percentage_24h = getFloat(data, "usd_24h_change"),
        .market_cap_change_24h = null,
        .market_cap_change_percentage_24h = null,
        .circulating_supply = null,
        .total_supply = null,
        .max_supply = null,
        .last_updated = try allocator.dupe(u8, "N/A"),
    };
}
