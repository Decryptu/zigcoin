const std = @import("std");
const types = @import("types.zig");
const json = @import("json.zig");
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
        _ = c.curl_easy_setopt(curl, c.CURLOPT_SSL_VERIFYPEER, @as(c_long, 1));
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
            BASE_URL ++ "/simple/price?ids={s}&vs_currencies=usd&include_market_cap=true&include_24hr_vol=true&include_24hr_change=true",
            .{coin_id},
        );

        var response = std.ArrayList(u8).init(self.allocator);
        defer response.deinit();

        try self.makeRequest(url, &response);
        return try json.parseMarketData(self.allocator, response.items, coin_id);
    }

    fn makeRequest(self: *Self, url: []const u8, response: *std.ArrayList(u8)) !void {
        _ = c.curl_easy_setopt(self.curl, c.CURLOPT_URL, url.ptr);
        _ = c.curl_easy_setopt(self.curl, c.CURLOPT_WRITEFUNCTION, writeCallback);
        _ = c.curl_easy_setopt(self.curl, c.CURLOPT_WRITEDATA, response);

        if (c.curl_easy_perform(self.curl) != c.CURLE_OK) {
            return error.RequestFailed;
        }
    }
};

fn writeCallback(data: [*c]u8, size: c_uint, nmemb: c_uint, user_data: *std.ArrayList(u8)) callconv(.C) c_uint {
    const real_size = size * nmemb;
    const slice = data[0..real_size];
    user_data.appendSlice(slice) catch return 0;
    return real_size;
}
