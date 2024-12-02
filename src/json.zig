const std = @import("std");
const types = @import("types.zig");

pub const JsonError = error{
    InvalidResponse,
    CoinNotFound,
    MissingField,
    InvalidFieldType,
    EmptyArray,
    NoDataFound,
};

pub fn parseMarketData(allocator: std.mem.Allocator, json_data: []const u8) !types.CoinInfo {
    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_data, .{});
    defer parsed.deinit();

    const root = parsed.value;

    if (root != .array) return JsonError.InvalidResponse;

    // Empty array means coin was not found
    if (root.array.items.len == 0) return JsonError.NoDataFound;

    // Get the first item since we're only requesting one coin
    const coin_data = root.array.items[0];
    if (coin_data != .object) return JsonError.InvalidResponse;

    const coin_obj = coin_data.object;

    // Helper function for safe value extraction
    const helpers = struct {
        fn getString(object: std.json.ObjectMap, key: []const u8) ![]const u8 {
            const val = object.get(key) orelse return JsonError.MissingField;
            return switch (val) {
                .string => |s| s,
                else => JsonError.InvalidFieldType,
            };
        }

        fn getFloat(object: std.json.ObjectMap, key: []const u8) !?f64 {
            const val = object.get(key) orelse return null;
            return switch (val) {
                .float => |f| f,
                .integer => |i| @floatFromInt(i),
                .null => null,
                else => JsonError.InvalidFieldType,
            };
        }

        fn getOptionalInt(object: std.json.ObjectMap, key: []const u8) !?i64 {
            const val = object.get(key) orelse return null;
            return switch (val) {
                .integer => |i| i,
                .float => |f| @intFromFloat(f),
                .null => null,
                else => null,
            };
        }
    };

    // Build CoinInfo struct
    const coin_info = types.CoinInfo{
        .id = try allocator.dupe(u8, try helpers.getString(coin_obj, "id")),
        .symbol = try allocator.dupe(u8, try helpers.getString(coin_obj, "symbol")),
        .name = try allocator.dupe(u8, try helpers.getString(coin_obj, "name")),
        .current_price = (try helpers.getFloat(coin_obj, "current_price")) orelse 0,
        .market_cap = (try helpers.getFloat(coin_obj, "market_cap")) orelse 0,
        .market_cap_rank = try helpers.getOptionalInt(coin_obj, "market_cap_rank"),
        .total_volume = (try helpers.getFloat(coin_obj, "total_volume")) orelse 0,
        .high_24h = try helpers.getFloat(coin_obj, "high_24h"),
        .low_24h = try helpers.getFloat(coin_obj, "low_24h"),
        .price_change_24h = try helpers.getFloat(coin_obj, "price_change_24h"),
        .price_change_percentage_24h = try helpers.getFloat(coin_obj, "price_change_percentage_24h"),
        .market_cap_change_24h = try helpers.getFloat(coin_obj, "market_cap_change_24h"),
        .market_cap_change_percentage_24h = try helpers.getFloat(coin_obj, "market_cap_change_percentage_24h"),
        .circulating_supply = try helpers.getFloat(coin_obj, "circulating_supply"),
        .total_supply = try helpers.getFloat(coin_obj, "total_supply"),
        .max_supply = try helpers.getFloat(coin_obj, "max_supply"),
        .last_updated = try allocator.dupe(u8, try helpers.getString(coin_obj, "last_updated")),
    };

    return coin_info;
}
