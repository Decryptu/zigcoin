const std = @import("std");
const types = @import("types.zig");

pub fn parseMarketData(allocator: std.mem.Allocator, json_data: []const u8, coin_id: []const u8) !types.CoinInfo {
    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_data, .{});
    defer parsed.deinit();

    const root = parsed.value;
    if (root != .object) return error.InvalidResponse;

    const data = root.object.get(coin_id) orelse return error.CoinNotFound;
    if (data != .object) return error.InvalidResponse;

    const market_data = data.object;

    // Helper function for safe value extraction
    const getValue = struct {
        fn float(map: std.json.ObjectMap, field: []const u8) ?f64 {
            const val = map.get(field) orelse return null;
            return switch (val) {
                .float => |f| f,
                .integer => |i| @floatFromInt(i),
                else => null,
            };
        }

        fn int(map: std.json.ObjectMap, field: []const u8) ?i64 {
            const val = map.get(field) orelse return null;
            return switch (val) {
                .integer => |i| i,
                else => null,
            };
        }
    };

    return types.CoinInfo{
        .id = try allocator.dupe(u8, coin_id),
        .symbol = try allocator.dupe(u8, coin_id),
        .name = try allocator.dupe(u8, coin_id),
        .current_price = getValue.float(market_data, "usd") orelse 0,
        .market_cap = getValue.float(market_data, "usd_market_cap") orelse 0,
        .market_cap_rank = getValue.int(market_data, "market_cap_rank"),
        .total_volume = getValue.float(market_data, "usd_24h_vol") orelse 0,
        .high_24h = getValue.float(market_data, "usd_24h_high"),
        .low_24h = getValue.float(market_data, "usd_24h_low"),
        .price_change_24h = getValue.float(market_data, "usd_24h_change"),
        .price_change_percentage_24h = getValue.float(market_data, "usd_24h_change_percentage"),
        .market_cap_change_24h = getValue.float(market_data, "usd_market_cap_24h_change"),
        .market_cap_change_percentage_24h = getValue.float(market_data, "usd_market_cap_24h_change_percentage"),
        .circulating_supply = getValue.float(market_data, "circulating_supply"),
        .total_supply = getValue.float(market_data, "total_supply"),
        .max_supply = getValue.float(market_data, "max_supply"),
        .last_updated = try allocator.dupe(u8, "N/A"),
    };
}
