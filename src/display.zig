const std = @import("std");
const types = @import("types.zig");

pub fn displayCoinInfo(writer: anytype, coin: types.CoinInfo) !void {
    // Create separator line based on name length
    const separator = try createSeparator(writer.context.allocator, coin.name.len);
    defer writer.context.allocator.free(separator);

    try writer.print(
        \\
        \\{s} ({s})
        \\{s}
        \\Price: ${d:.2}
        \\Market Cap: ${d:.2}
        \\24h Volume: ${d:.2}
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
    ,
        .{
            coin.name,
            coin.symbol,
            separator,
            coin.current_price,
            coin.market_cap,
            coin.total_volume,
            coin.price_change_percentage_24h,
            coin.market_cap_rank,
            coin.circulating_supply,
            coin.total_supply,
            coin.max_supply,
            coin.last_updated,
        },
    );
}

fn createSeparator(allocator: std.mem.Allocator, len: usize) ![]u8 {
    const separator = try allocator.alloc(u8, len);
    @memset(separator, '=');
    return separator;
}
