const std = @import("std");
const types = @import("types.zig");

pub fn displayCoinInfo(allocator: std.mem.Allocator, writer: anytype, coin: types.CoinInfo) !void {
    const separator = try createSeparator(allocator, coin.name.len);
    defer allocator.free(separator);

    try writer.print(
        \\
        \\{s} ({s})
        \\{s}
        \\Price: ${d:.2}
        \\Market Cap: ${d:.0}
        \\24h Volume: ${d:.0}
        \\24h Change: {?d:.2}%
        \\Market Cap Rank: {?d}
        \\
        \\Supply
        \\-----
        \\Circulating: {?d:.0}
        \\Total: {?d:.0}
        \\Max: {?d:.0}
        \\
        \\Last Updated: {s}
        \\
    , .{
        coin.name,
        coin.symbol,
        separator,
        @round(coin.current_price * 100) / 100, // Format price with 2 decimal places
        coin.market_cap,
        coin.total_volume,
        coin.price_change_percentage_24h,
        coin.market_cap_rank,
        coin.circulating_supply,
        coin.total_supply,
        coin.max_supply,
        coin.last_updated,
    });
}

fn createSeparator(allocator: std.mem.Allocator, len: usize) ![]u8 {
    const separator = try allocator.alloc(u8, len);
    @memset(separator, '=');
    return separator;
}
