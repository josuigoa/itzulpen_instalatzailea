const std = @import("std");
const builtin = @import("builtin");

pub const string = []const u8;

pub fn concat(slices: []const string) !string {
    return try std.mem.concat(
        std.heap.page_allocator,
        u8,
        slices,
    );
}

pub fn apply_separator(path: string) !string {
    if (builtin.os.tag != .windows)
        return path;
    const buf = try std.heap.page_allocator.alloc(u8, path.len);
    _ = std.mem.replace(u8, path, "/", "\\", buf);
    return buf;
}
