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
    var client = try api.ApiClient.init(allocator);
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
    const coin_info = try client.fetchCoinInfo(coin_id);
    defer coin_info.deinit(allocator);

    try display.displayCoinInfo(allocator, stdout, coin_info);
}
