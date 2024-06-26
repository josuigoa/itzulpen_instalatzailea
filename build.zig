const std = @import("std");

pub fn build(b: *std.Build) !void {
    const data_opt = b.option([]const u8, "installer-data", "Game translation installer directory path");

    if (data_opt) |data| {
        const cp_cmd = b.addSystemCommand(&[_][]const u8{
            "cp",
            "-r",
            data,
            "src/",
        });
        const optimize = b.standardOptimizeOption(.{});
        const target = b.standardTargetOptions(.{});

        const libui = b.dependency("libui", .{
            .target = target,
            .optimize = optimize,
        });

        const ui_artifact = libui.artifact("ui");

        // Re-export libui artifact
        b.installArtifact(ui_artifact);

        const ui_module = b.addModule("ui", .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "lib/ui.zig",
                },
            },
        });

        const utils_module = b.addModule("utils", .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/utils.zig",
                },
            },
        });

        const exe = b.addExecutable(.{
            .name = "installer",
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/main_installer.zig",
                },
            },
            .target = target,
            .optimize = optimize,
        });

        exe.subsystem = std.Target.SubSystem.Windows;
        exe.root_module.addImport("utils", utils_module);
        exe.root_module.addImport("ui", ui_module);
        exe.linkLibrary(ui_artifact);

        const zigimg_module = b.dependency("zigimg", .{
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("zigimg", zigimg_module.module("zigimg"));

        if (target.result.isDarwin()) {
            @import("macos_sdk").addPaths(ui_artifact);
            ui_artifact.linkFramework("AppKit");
            ui_artifact.linkFramework("Foundation");
            exe.linkSystemLibrary("objc");

            @import("macos_sdk").addPaths(exe);
            exe.linkFramework("AppKit");
            exe.linkFramework("Foundation");
            exe.linkFramework("ApplicationServices");
            exe.linkFramework("ColorSync");
            exe.linkFramework("CoreGraphics");
            exe.linkFramework("CoreText");
            exe.linkFramework("CoreServices");
            exe.linkFramework("CoreFoundation");
            exe.linkFramework("CFNetwork");
            exe.linkFramework("ImageIO");
        } else if (target.result.os.tag == .windows) {
            exe.addWin32ResourceFile(.{
                .file = .{
                    .src_path = .{
                        .owner = b,
                        .sub_path = "src/windows/resources.rc",
                    },
                },
            });
        }

        exe.step.dependOn(&cp_cmd.step);

        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe.step);

        const run_step = b.step("run", "Run the installer app");
        run_step.dependOn(&run_cmd.step);
    } else {
        std.debug.print("[installer-data] option is mandatory.\n", .{});
    }
}
