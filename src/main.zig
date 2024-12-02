const std = @import("std");
const api = @import("api.zig");
const display = @import("display.zig");

pub fn main() !void {
    // Initialize general purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Get stdout
    const stdout_file = std.io.getStdOut();
    const stdout = stdout_file.writer();

    // Initialize API client
    var client = api.ApiClient.init(allocator) catch |err| {
        try stdout.print("Failed to initialize API client: {any}\n", .{err});
        return err;
    };
    defer client.deinit();

    // Get command line arguments
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // Skip program name
    _ = args.next();

    // Get coin ID from arguments
    const coin_id = args.next() orelse {
        try stdout.writeAll("Usage: zigcoin <coin-id>\nExample: zigcoin bitcoin\n");
        std.process.exit(1);
    };

    // Fetch and display coin information
    const coin_info = client.fetchCoinInfo(coin_id) catch |err| {
        switch (err) {
            error.CoinNotFound => try stdout.print("Error: Coin '{s}' not found\n", .{coin_id}),
            error.RateLimitExceeded => try stdout.writeAll("Error: Rate limit exceeded. Please try again later\n"),
            error.RequestFailed => try stdout.writeAll("Error: Failed to fetch data from CoinGecko API\n"),
            else => try stdout.print("Error: {any}\n", .{err}),
        }
        return err;
    };
    defer coin_info.deinit(allocator);

    try display.displayCoinInfo(allocator, stdout, coin_info);
}
