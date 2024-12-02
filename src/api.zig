const std = @import("std");
const types = @import("types.zig");
const json = @import("json.zig");
const c = @cImport({
    @cInclude("curl/curl.h");
});

const BASE_URL = "https://api.coingecko.com/api/v3";

pub const ApiError = error{
    CurlInitFailed,
    CurlSetupFailed,
    RequestFailed,
    RateLimitExceeded,
    CoinNotFound,
    EmptyResponse,
};

pub const ApiClient = struct {
    allocator: std.mem.Allocator,
    curl: *c.CURL,
    headers: *c.curl_slist,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        const curl = c.curl_easy_init() orelse return ApiError.CurlInitFailed;
        errdefer c.curl_easy_cleanup(curl);

        // Set up headers
        var headers = c.curl_slist_append(null, "Accept: application/json") orelse return ApiError.CurlInitFailed;
        errdefer c.curl_slist_free_all(headers);
        headers = c.curl_slist_append(headers, "User-Agent: Zigcoin/1.0") orelse {
            c.curl_slist_free_all(headers);
            return ApiError.CurlInitFailed;
        };

        // Configure CURL with error checking
        if (c.curl_easy_setopt(curl, c.CURLOPT_HTTPHEADER, headers) != c.CURLE_OK) return ApiError.CurlSetupFailed;
        if (c.curl_easy_setopt(curl, c.CURLOPT_SSL_VERIFYPEER, @as(c_long, 1)) != c.CURLE_OK) return ApiError.CurlSetupFailed;
        if (c.curl_easy_setopt(curl, c.CURLOPT_TIMEOUT, @as(c_long, 10)) != c.CURLE_OK) return ApiError.CurlSetupFailed;
        if (c.curl_easy_setopt(curl, c.CURLOPT_FOLLOWLOCATION, @as(c_long, 1)) != c.CURLE_OK) return ApiError.CurlSetupFailed;

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
        // Add null terminator by using sentinel-terminated slice
        const url = try std.fmt.bufPrintZ(
            &url_buf,
            "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids={s}",
            .{coin_id},
        );

        var response = std.ArrayList(u8).init(self.allocator);
        defer response.deinit();

        // Reset CURL handle
        c.curl_easy_reset(self.curl);

        // Set request options with the null-terminated string
        if (c.curl_easy_setopt(self.curl, c.CURLOPT_URL, @as([*:0]const u8, url.ptr)) != c.CURLE_OK) return ApiError.CurlSetupFailed;
        if (c.curl_easy_setopt(self.curl, c.CURLOPT_HTTPHEADER, self.headers) != c.CURLE_OK) return ApiError.CurlSetupFailed;
        if (c.curl_easy_setopt(self.curl, c.CURLOPT_WRITEFUNCTION, writeCallback) != c.CURLE_OK) return ApiError.CurlSetupFailed;
        if (c.curl_easy_setopt(self.curl, c.CURLOPT_WRITEDATA, &response) != c.CURLE_OK) return ApiError.CurlSetupFailed;

        // Perform request
        const result = c.curl_easy_perform(self.curl);
        if (result != c.CURLE_OK) {
            std.debug.print("CURL error: {s}\n", .{c.curl_easy_strerror(result)});
            return ApiError.RequestFailed;
        }

        // Check HTTP status code
        var status_code: c_long = undefined;
        _ = c.curl_easy_getinfo(self.curl, c.CURLINFO_RESPONSE_CODE, &status_code);

        switch (status_code) {
            200 => {},
            404 => return ApiError.CoinNotFound,
            429 => return ApiError.RateLimitExceeded,
            else => {
                std.debug.print("HTTP error: {d}\n", .{status_code});
                return ApiError.RequestFailed;
            },
        }

        if (response.items.len == 0) {
            return ApiError.EmptyResponse;
        }

        return try json.parseMarketData(self.allocator, response.items);
    }
};

fn writeCallback(data: [*c]u8, size: c_uint, nmemb: c_uint, user_data: *std.ArrayList(u8)) callconv(.C) c_uint {
    const real_size = size * nmemb;
    const slice = data[0..real_size];
    user_data.appendSlice(slice) catch return 0;
    return real_size;
}
