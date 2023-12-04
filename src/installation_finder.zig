const std = @import("std");
const data = @import("data/installer.zig");
const builtin = @import("builtin");
const utils = @import("utils");

const string = []const u8;
const Dir = std.fs.Dir;

pub fn find_installation() ?string {
    var found: bool = false;
    var game_path: string = undefined;

    if (find_steam_game()) |s_found| {
        found = true;
        game_path = s_found;
    } else |_| {
        // std.debug.print("Error finding game in Steam {s}", .{s_err});
        if (find_gog_game()) |g_found| {
            found = true;
            game_path = g_found;
        } else |_| {
            // std.debug.print("Error finding game in Steam {s}", .{g_err});
        }
    }

    if (found) {
        std.debug.print("Found install directory {s}\n", .{game_path});
        return game_path;
    }

    return null;
}

fn find_steam_game() !string {
    const possible_paths = try get_steam_paths();
    const game_names = data.get_game_names();
    var path: string = undefined;

    for (possible_paths) |possible_path| {
        if (possible_path.len == 0) continue;
        for (game_names) |game_name| {
            if (game_name.len == 0) continue;

            path = try utils.apply_separator(try utils.concat(&.{ possible_path, "/", game_name }));
            if (std.fs.accessAbsolute(path, std.fs.File.OpenFlags{})) {
                return path;
            } else |_| {
                if (read_libraryfolders(path)) |library_paths| {
                    for (library_paths) |lib_path| {
                        path = try utils.apply_separator(try utils.concat(&.{ lib_path, "/", game_name }));
                        if (std.fs.accessAbsolute(path, std.fs.File.OpenFlags{})) {
                            return path;
                        } else |_| {
                            std.heap.page_allocator.free(path);
                        }
                    }
                } else |_| {
                    std.heap.page_allocator.free(path);
                }
            }
        }
    }

    return Dir.AccessError.FileNotFound;
}

fn read_libraryfolders(base_path: string) ![10]string {
    const path = try utils.apply_separator(try utils.concat(&.{ base_path, "/libraryfolders.vdf" }));
    var file = try std.fs.cwd().openFile(path, .{});

    defer file.close();
    defer std.heap.page_allocator.free(path);

    var paths: [10]string = undefined;
    var paths_ind: usize = 0;

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    const not_found_index = 1000;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const index = std.mem.indexOf(u8, line, "\"path\"") orelse not_found_index;
        if (index != not_found_index) {
            var path_start_ind: usize = 0;
            for (line, 0..) |char, ind| {
                if (ind < index + 6) continue;
                if (char == '\t') continue;
                if (char == '"') {
                    path_start_ind = ind;
                    break;
                }
            }

            const lenght = line.len - path_start_ind - 2;

            if (std.heap.page_allocator.alloc(u8, lenght)) |new_str| {
                @memcpy(new_str, line[path_start_ind + 1 .. line.len - 1]);
                paths[paths_ind] = new_str;
                paths_ind += 1;
            } else |_| {}
        }
    }

    return paths;
}

fn find_gog_game() !string {
    const possible_paths = try get_gog_paths();
    const game_names = data.get_game_names();
    var path: string = undefined;

    for (possible_paths) |possible_path| {
        if (possible_path.len == 0) continue;
        for (game_names) |game_name| {
            if (game_name.len == 0) continue;

            path = try utils.apply_separator(try utils.concat(&.{ possible_path, "/", game_name }));
            std.fs.accessAbsolute(path, std.fs.File.OpenFlags{}) catch |err| {
                if (err == Dir.AccessError.FileNotFound) {
                    std.debug.print("{s} ez da aurkitu: {?}\n", .{ path, err });
                    std.heap.page_allocator.free(path);
                    continue;
                }
            };

            return path;
        }
    }

    return Dir.AccessError.FileNotFound;
}

fn get_steam_paths() ![10]string {
    var paths: [10]string = undefined;
    if (builtin.os.tag == .windows) {
        const program_files = try std.process.getEnvVarOwned(std.heap.page_allocator, "%PROGRAMFILES%");
        const program_files_x86 = try std.process.getEnvVarOwned(std.heap.page_allocator, "%PROGRAMFILES(X86)%");
        const username = try std.process.getEnvVarOwned(std.heap.page_allocator, "%USERNAME%");
        paths[0] = try utils.concat(&.{ program_files, "\\Steam" });
        paths[1] = try utils.concat(&.{ program_files_x86, "\\Steam" });
        paths[2] = "z:\\home\\deck\\.steam\\steam";
        paths[3] = try utils.concat(&.{ "z:\\home\\", username, "\\.steam\\steam" });
    } else if (builtin.os.tag == .linux) {
        const home_dir = try std.process.getEnvVarOwned(std.heap.page_allocator, "HOME");
        paths[0] = try utils.concat(&.{ home_dir, "/.steam/steam" });
    } else {
        const home_dir = try std.process.getEnvVarOwned(std.heap.page_allocator, "HOME");
        paths[0] = try utils.concat(&.{ home_dir, "/Library/Application Support/Steam/steamapps/common" });
    }

    return paths;
}

fn get_gog_paths() ![10]string {
    var paths: [10]string = undefined;
    if (builtin.os.tag == .windows) {
        const program_files = try std.process.getEnvVarOwned(std.heap.page_allocator, "%PROGRAMFILES%");
        const program_files_x86 = try std.process.getEnvVarOwned(std.heap.page_allocator, "%PROGRAMFILES(X86)%");
        paths[0] = try utils.concat(&.{ program_files, "/GOG Games" });
        paths[1] = try utils.concat(&.{ program_files, "/GOG Galaxy/Games" });
        paths[2] = try utils.concat(&.{ program_files_x86, "/GOG Games" });
        paths[3] = try utils.concat(&.{ program_files_x86, "/GOG Galaxy/Games" });
    } else if (builtin.os.tag == .linux) {
        const home_dir = try std.process.getEnvVarOwned(std.heap.page_allocator, "HOME");
        paths[0] = try utils.concat(&.{ home_dir, "/GOG Games" });
        paths[1] = try utils.concat(&.{ home_dir, "/GOG Galaxy/Games" });
    } else {
        const home_dir = try std.process.getEnvVarOwned(std.heap.page_allocator, "HOME");
        paths[0] = try utils.concat(&.{ home_dir, "/Library/Application Support/" });
    }

    return paths;
}
