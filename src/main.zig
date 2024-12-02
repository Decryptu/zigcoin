const std = @import("std");
const api = @import("api.zig");
const display = @import("display.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout_file = std.io.getStdOut();
    const stdout = stdout_file.writer();

    var client = api.ApiClient.init(allocator) catch |err| {
        try stdout.print("Failed to initialize API client: {any}\n", .{err});
        return err;
    };
    defer client.deinit();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next();

    const coin_id = args.next() orelse {
        try stdout.writeAll("Usage: zigcoin <coin-id>\nExample: zigcoin bitcoin\n");
        std.process.exit(1);
    };

    const coin_info = client.fetchCoinInfo(coin_id) catch |err| {
        switch (err) {
            error.CoinNotFound => try stdout.print("Error: Coin '{s}' not found\n", .{coin_id}),
            error.RateLimitExceeded => try stdout.writeAll("Error: Rate limit exceeded. Please try again later\n"),
            error.RequestFailed => try stdout.writeAll("Error: Failed to fetch data from CoinGecko API\n"),
            error.NoDataFound => try stdout.print("Error: No data found for coin '{s}'. Please check the coin ID and try again.\n", .{coin_id}),
            error.EmptyArray => try stdout.print("Error: No data found for coin '{s}'\n", .{coin_id}),
            error.InvalidResponse => try stdout.writeAll("Error: Invalid response from API\n"),
            error.MissingField => try stdout.writeAll("Error: Missing data in API response\n"),
            error.InvalidFieldType => try stdout.writeAll("Error: Invalid data format in API response\n"),
            else => try stdout.print("Unexpected error: {s}\n", .{@errorName(err)}),
        }
        return err;
    };
    defer coin_info.deinit(allocator);

    try display.displayCoinInfo(allocator, stdout, coin_info);
}
