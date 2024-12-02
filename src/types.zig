const std = @import("std");

// Core data structures for cryptocurrency information
pub const CoinInfo = struct {
    id: []const u8,
    symbol: []const u8,
    name: []const u8,
    current_price: f64,
    market_cap: f64,
    market_cap_rank: ?i64,
    total_volume: f64,
    high_24h: ?f64,
    low_24h: ?f64,
    price_change_24h: ?f64,
    price_change_percentage_24h: ?f64,
    market_cap_change_24h: ?f64,
    market_cap_change_percentage_24h: ?f64,
    circulating_supply: ?f64,
    total_supply: ?f64,
    max_supply: ?f64,
    last_updated: []const u8,

    pub fn deinit(self: *const CoinInfo, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.symbol);
        allocator.free(self.name);
        allocator.free(self.last_updated);
    }
};

pub const ApiError = error{
    RequestFailed,
    InvalidResponse,
    CoinNotFound,
    RateLimitExceeded,
    EmptyResponse,
    CurlInitFailed,
};
