const std = @import("std");
const types = @import("types.zig");
const c = @cImport({
    @cInclude("curl/curl.h");
});

const BASE_URL = "https://api.coingecko.com/api/v3";

pub const ApiClient = struct {
    allocator: std.mem.Allocator,
    curl: *c.CURL,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        const curl = c.curl_easy_init() orelse return error.CurlInitFailed;
        return Self{
            .allocator = allocator,
            .curl = curl,
        };
    }

    pub fn deinit(self: *Self) void {
        c.curl_easy_cleanup(self.curl);
    }

    pub fn fetchCoinInfo(self: *Self, coin_id: []const u8) !types.CoinInfo {
        var url_buf: [256]u8 = undefined;
        const url = try std.fmt.bufPrint(
            &url_buf,
            BASE_URL ++ "/simple/price?ids={s}&vs_currencies=usd&include_market_cap=true&include_24hr_vol=true&include_24hr_change=true&include_last_updated_at=true",
            .{coin_id},
        );

        var response = std.ArrayList(u8).init(self.allocator);
        defer response.deinit();

        try self.makeRequest(url, &response);

        // Parse the JSON response
        return try self.parseCoinInfo(response.items, coin_id);
    }

    fn makeRequest(self: *Self, url: []const u8, response: *std.ArrayList(u8)) !void {
        _ = c.curl_easy_setopt(self.curl, c.CURLOPT_URL, url.ptr);
        _ = c.curl_easy_setopt(self.curl, c.CURLOPT_WRITEFUNCTION, writeCallback);
        _ = c.curl_easy_setopt(self.curl, c.CURLOPT_WRITEDATA, response);

        const res = c.curl_easy_perform(self.curl);
        if (res != c.CURLE_OK) {
            return error.RequestFailed;
        }
    }

    fn parseCoinInfo(self: *Self, json_data: []const u8, coin_id: []const u8) !types.CoinInfo {
        _ = json_data; // TODO: Implement proper JSON parsing

        // For now returning dummy data with the actual coin_id
        return types.CoinInfo{
            .id = try self.allocator.dupe(u8, coin_id),
            .symbol = try self.allocator.dupe(u8, "btc"),
            .name = try self.allocator.dupe(u8, "Bitcoin"),
            .current_price = 45000.0,
            .market_cap = 800000000000.0,
            .market_cap_rank = 1,
            .total_volume = 24000000000.0,
            .high_24h = 46000.0,
            .low_24h = 44000.0,
            .price_change_24h = 1000.0,
            .price_change_percentage_24h = 2.5,
            .market_cap_change_24h = 20000000000.0,
            .market_cap_change_percentage_24h = 2.1,
            .circulating_supply = 19000000.0,
            .total_supply = 21000000.0,
            .max_supply = 21000000.0,
            .last_updated = try self.allocator.dupe(u8, "2024-01-01T00:00:00Z"),
        };
    }
};

fn writeCallback(data: [*c]u8, size: c_uint, nmemb: c_uint, user_data: *std.ArrayList(u8)) callconv(.C) c_uint {
    const real_size = size * nmemb;
    const slice = data[0..real_size];
    user_data.appendSlice(slice) catch return 0;
    return real_size;
}
