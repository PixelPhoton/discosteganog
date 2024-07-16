const std = @import("std");

/// a 'ternary byte' - has 9.5 bits
const Tryte = [6]u2;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const args = try std.process.argsAlloc(arena.allocator());
    defer std.process.argsFree(arena.allocator(), args);
    if (args.len < 2 or args[1].len < 3) {
        std.log.err("1st arg must be: enc to encode, dec to decode", .{});
        return;
    }

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var read = try stdin.readAllAlloc(arena.allocator(), 1024 * 1024);
    if (read[read.len - 1] == '\n') read.len -= 1;
    if (read[read.len - 1] == '\r') read.len -= 1;

    try stdout.print("{s}", .{switch (std.mem.bytesAsValue(u24, args[1][0..3]).*) {
        std.mem.bytesAsValue(u24, "enc").* => try encode(arena.allocator(), read),
        std.mem.bytesAsValue(u24, "dec").* => try decode(arena.allocator(), read),
        else => {
            std.log.err("1st arg must be: enc to encode, dec to decode", .{});
            return;
        },
    }});
}

/// encodes str to the format
/// caller owns returned memory
fn encode(allocator: std.mem.Allocator, str: []const u8) ![]const u8 {
    var out_pos: usize = 0;
    var out: []u8 = try allocator.alloc(u8, str.len);
    for (str) |char| {
        var len: i8 = 0;
        const tryte = byteToTryte(char);
        for (tryte) |trit| len += @as(u7, trit) + 5;

        // prevent segfault
        while (out.len - out_pos < len) out = try allocator.realloc(out, out.len * 2);

        for (tryte) |trit| {
            @memcpy(out[out_pos..][0..3], "-# ");
            out_pos += 3;
            for (0..trit + 1) |_| {
                out[out_pos] = '#';
                out_pos += 1;
            }
            out[out_pos] = ' ';
            out_pos += 1;
        }
    }
    const end_len = comptime (std.unicode.utf8CodepointSequenceLength('⠀') catch unreachable) + 2;
    const final_len = out_pos + end_len;
    if (out.len != final_len) out = try allocator.realloc(out, final_len);
    @memcpy(out[out_pos..][0..end_len], "⠀ #");
    return out;
}

/// decodes str from the format
/// caller owns returned memory
fn decode(allocator: std.mem.Allocator, str: []const u8) ![]const u8 {
    var out_pos: usize = 0;
    // no additional allocations needed as encoded is always longer than decoded
    var out: []u8 = try allocator.alloc(u8, str.len);
    var codes = std.mem.tokenizeSequence(u8, str, "-# ");
    outer: while (true) {
        var tryte: Tryte = .{0} ** 6;

        for (&tryte) |*trit| {
            for (codes.next() orelse break :outer) |ch| {
                if (ch == '#') trit.* += 1 else break;
            }
            if (trit.* == 0) break :outer;
            trit.* -= 1;
        }
        out[out_pos] = tryteToByte(tryte);
        out_pos += 1;
    }

    out = try allocator.realloc(out, out_pos);
    return out;
}

/// converts tryte to a byte, discarding the extra 1.5 bits
fn tryteToByte(tryte: Tryte) u8 {
    var result: u8 = 0;
    for (tryte) |trit| {
        result *|= 3;
        result +|= trit;
    }
    return result;
}

/// converts byte to a tryte
fn byteToTryte(byte: u8) Tryte {
    var val = byte;
    var result: Tryte = undefined;
    comptime var i: u3 = result.len - 1;
    inline while (i < result.len) : (i -%= 1) {
        result[i] = @intCast(val % 3);
        val /= 3;
    }
    return result;
}
