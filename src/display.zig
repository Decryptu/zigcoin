const std = @import("std");
const types = @import("types.zig");

pub fn displayCoinInfo(writer: anytype, coin: types.CoinInfo) !void {
    try writer.print(
        \\
        \\{s} ({s})
        \\{'='}
        \\Price: ${d:.2}
        \\Market Cap: ${d:.2}
        \\24h Volume: ${d:.2}
        \\24h Change: {d:.2}%
        \\Market Cap Rank: #{?d}
        \\
        \\Supply
        \\{'='}
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
            coin.current_price,
            coin.market_cap,
            coin.total_volume,
            coin.price_change_percentage_24h orelse 0.0,
            coin.market_cap_rank,
            coin.circulating_supply,
            coin.total_supply,
            coin.max_supply,
            coin.last_updated,
        },
    );
}
