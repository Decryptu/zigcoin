const std = @import("std");
const types = @import("types.zig");

pub fn parseMarketData(allocator: std.mem.Allocator, json_data: []const u8, coin_id: []const u8) !types.CoinInfo {
    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_data, .{});
    defer parsed.deinit();

    const root = parsed.value;
    if (root != .object) return error.InvalidResponse;

    const market_data = root.object;
    const data = market_data.get(coin_id) orelse return error.CoinNotFound;
    if (data != .object) return error.InvalidResponse;

    const coin_data = data.object;

    // Helper function for safe number extraction
    const getNumber = struct {
        fn float(obj: std.json.ObjectMap, field: []const u8) ?f64 {
            if (obj.get(field)) |value| {
                return switch (value) {
                    .float => |f| f,
                    .integer => |i| @as(f64, @floatFromInt(i)),
                    else => null,
                };
            }
            return null;
        }
    };

    // Extract direct USD price
    const usd_data = coin_data.get("usd") orelse return error.InvalidResponse;
    const current_price = switch (usd_data) {
        .float => |f| f,
        .integer => |i| @as(f64, @floatFromInt(i)),
        else => return error.InvalidResponse,
    };

    return types.CoinInfo{
        .id = try allocator.dupe(u8, coin_id),
        .symbol = try allocator.dupe(u8, coin_id),
        .name = try allocator.dupe(u8, coin_id),
        .current_price = current_price,
        .market_cap = getNumber.float(coin_data, "usd_market_cap") orelse 0,
        .market_cap_rank = null, // Not available in simple price endpoint
        .total_volume = getNumber.float(coin_data, "usd_24h_vol") orelse 0,
        .high_24h = null, // Not available in simple price endpoint
        .low_24h = null, // Not available in simple price endpoint
        .price_change_24h = null,
        .price_change_percentage_24h = getNumber.float(coin_data, "usd_24h_change"),
        .market_cap_change_24h = null,
        .market_cap_change_percentage_24h = null,
        .circulating_supply = null, // Not available in simple price endpoint
        .total_supply = null, // Not available in simple price endpoint
        .max_supply = null, // Not available in simple price endpoint
        .last_updated = try allocator.dupe(u8, "N/A"),
    };
}
