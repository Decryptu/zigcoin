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
    headers: *c.curl_slist,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        const curl = c.curl_easy_init() orelse return error.CurlInitFailed;

        // Set up headers
        var headers = c.curl_slist_append(null, "Accept: application/json") orelse return error.CurlInitFailed;
        headers = c.curl_slist_append(headers, "User-Agent: Zigcoin/1.0") orelse return error.CurlInitFailed;

        // Configure CURL
        _ = c.curl_easy_setopt(curl, c.CURLOPT_HTTPHEADER, headers);
        _ = c.curl_easy_setopt(curl, c.CURLOPT_SSL_VERIFYPEER, @as(c_long, 1));
        _ = c.curl_easy_setopt(curl, c.CURLOPT_TIMEOUT, @as(c_long, 10)); // 10 second timeout
        _ = c.curl_easy_setopt(curl, c.CURLOPT_FOLLOWLOCATION, @as(c_long, 1));

        return Self{
            .allocator = allocator,
            .curl = curl,
            .headers = headers,
        };
    }

    pub fn deinit(self: *Self) void {
        c.curl_slist_free_all(self.headers);
        c.curl_easy_cleanup(self.curl);
    }

    pub fn fetchCoinInfo(self: *Self, coin_id: []const u8) !types.CoinInfo {
        var url_buf: [512]u8 = undefined;
        const url = try std.fmt.bufPrint(
            &url_buf,
            BASE_URL ++ "/simple/price?ids={s}&vs_currencies=usd&include_market_cap=true&include_24hr_vol=true&include_24hr_change=true&include_last_updated_at=true",
            .{coin_id},
        );

        var response = std.ArrayList(u8).init(self.allocator);
        defer response.deinit();

        try self.makeRequest(url, &response);

        // Check if response is empty
        if (response.items.len == 0) {
            return error.EmptyResponse;
        }

        return try json.parseMarketData(self.allocator, response.items, coin_id);
    }

    fn makeRequest(self: *Self, url: []const u8, response: *std.ArrayList(u8)) !void {
        // Reset CURL handle
        c.curl_easy_reset(self.curl);

        // Set options
        _ = c.curl_easy_setopt(self.curl, c.CURLOPT_URL, url.ptr);
        _ = c.curl_easy_setopt(self.curl, c.CURLOPT_HTTPHEADER, self.headers);
        _ = c.curl_easy_setopt(self.curl, c.CURLOPT_WRITEFUNCTION, writeCallback);
        _ = c.curl_easy_setopt(self.curl, c.CURLOPT_WRITEDATA, response);

        const result = c.curl_easy_perform(self.curl);
        if (result != c.CURLE_OK) {
            return error.RequestFailed;
        }

        // Check HTTP status code
        var status_code: c_long = undefined;
        _ = c.curl_easy_getinfo(self.curl, c.CURLINFO_RESPONSE_CODE, &status_code);

        switch (status_code) {
            200 => {}, // OK
            429 => return error.RateLimitExceeded,
            404 => return error.CoinNotFound,
            else => return error.RequestFailed,
        }
    }
};

fn writeCallback(data: [*c]u8, size: c_uint, nmemb: c_uint, user_data: *std.ArrayList(u8)) callconv(.C) c_uint {
    const real_size = size * nmemb;
    const slice = data[0..real_size];
    user_data.appendSlice(slice) catch return 0;
    return real_size;
}
