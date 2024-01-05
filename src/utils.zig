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

pub fn look_for_dir(base_path: string, dir_name: string) !string {
    const base_dir = try std.fs.openDirAbsolute(base_path, std.fs.Dir.OpenDirOptions{
        .access_sub_paths = true,
        .iterate = true,
        .no_follow = true,
    });

    var iter = base_dir.iterate();
    while (true) {
        const entry = try iter.next();
        if (entry == null) {
            break;
        }

        switch (entry.?.kind) {
            .directory => {
                if (std.mem.eql(u8, entry.?.name, dir_name)) {
                    return try concat(&.{ base_path, "/", dir_name });
                } else {
                    const val = try look_for_dir(try concat(&.{ base_path, "/", entry.?.name }), dir_name);
                    if (val.len != 0) {
                        return val;
                    }
                }
            },
            else => {},
        }
    }

    return "";
}

pub fn look_for_file(base_path: string, file_name: string) !string {
    const base_dir = try std.fs.openDirAbsolute(base_path, std.fs.Dir.OpenDirOptions{
        .access_sub_paths = true,
        .iterate = true,
        .no_follow = true,
    });

    var iter = base_dir.iterate();
    while (true) {
        const entry = try iter.next();
        if (entry == null) {
            break;
        }

        switch (entry.?.kind) {
            .file => {
                if (std.mem.eql(u8, entry.?.name, file_name)) {
                    return try concat(&.{ base_path, "/", file_name });
                }
            },
            .directory => {
                const val = try look_for_file(try concat(&.{ base_path, "/", entry.?.name }), file_name);
                if (val.len != 0) {
                    return val;
                }
            },
            else => {},
        }
    }

    return "";
}
