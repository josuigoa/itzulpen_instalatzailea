const std = @import("std");
const ui = @import("ui");
const zigimg = @import("zigimg");
const utils = @import("utils");
const builtin = @import("builtin");
const installation_finder = @import("installation_finder.zig");
const data = @import("data/installer.zig");
// const header_png = @embedFile("data/header.png");

pub const App = struct {
    window: *ui.Window,
    install_path_entry: *ui.Entry,
    install_btn: *ui.Button,
};

pub fn main() !void {
    const game_path = installation_finder.find_installation() orelse "";

    var init_data = ui.InitData{
        .options = .{ .Size = 0 },
    };
    ui.Init(&init_data) catch {
        std.debug.print("Error initializing LibUI: {s}\n", .{init_data.get_error()});
        init_data.free_error();
        return;
    };
    defer ui.Uninit();

    // irudia agertzea lortzean hau erabili
    // const window_width = if (builtin.os.tag == .linux) 550 else 400;
    // const window_height = if (builtin.os.tag == .linux) 330 else 160;

    const window_width = 400;
    const window_height = 160;

    const main_window = try ui.Window.New("Itzulpen instalatzailea", window_width, window_height, .hide_menubar);
    main_window.SetMargined(true);
    main_window.as_control().Show();
    main_window.OnClosing(void, on_closing, null);

    const v_box = try ui.Box.New(.Vertical);
    v_box.SetPadded(true);
    main_window.SetChild(v_box.as_control());

    if (builtin.os.tag == .linux) {
        // var model_handler = ui.Table.Model.Handler{
        //     .NumColumns = num_cols,
        //     .NumRows = num_rows,
        //     .ColumnType = col_type,
        //     .CellValue = cell_value,
        //     .SetCellValue = set_cell_value,
        // };
        // var table_params = ui.Table.Params{
        //     .Model = try ui.Table.Model.New(&model_handler),
        //     .RowBackgroundColorModelColumn = -1,
        // };
        // const table = try ui.Table.New(&table_params);
        // table.AppendColumn("", .{ .Image = .{
        //     .image_column = 1,
        // } });
        // table.HeaderSetVisible(false);
        // v_box.Append(table.as_control(), .stretch);
    }

    const joko_izena = data.get_game_names()[0];

    const testua: utils.string = if (std.mem.eql(u8, "", game_path))
        "Ez da instalaziorik aurkitu, bilatu zuk mesedez."
    else
        "Ondorengo bidean aurkitu da instalazioa, egiaztatu zuzena ote den.";
    const label_text = try utils.concat(&.{ "[", joko_izena, "] jokoa euskaratzeko instalatzailea\n", testua });
    const label = try ui.Label.New(@ptrCast(label_text));
    v_box.Append(label.as_control(), .dont_stretch);

    const bide_box = try ui.Box.New(.Horizontal);
    bide_box.SetPadded(true);
    v_box.Append(bide_box.as_control(), .dont_stretch);

    const install_path_entry = try ui.Entry.New(ui.Entry.Type.Entry);
    bide_box.Append(install_path_entry.as_control(), .stretch);

    const find_btn = try ui.Button.New("Bilatu");
    bide_box.Append(find_btn.as_control(), .dont_stretch);

    const install_btn = try ui.Button.New("Instalatu");
    v_box.Append(install_btn.as_control(), .dont_stretch);

    install_path_entry.SetText(@ptrCast(game_path));

    var app = App{
        .window = main_window,
        .install_path_entry = install_path_entry,
        .install_btn = install_btn,
    };

    check_intall_path_empty(&app);
    install_path_entry.OnChanged(App, on_path_changed, &app);
    find_btn.OnClicked(App, get_folder, &app);
    install_btn.OnClicked(App, install_translation, &app);

    ui.Main();
}

// fn num_cols(_: *ui.Table.Model.Handler, _: *ui.Table.Model) callconv(.C) c_int {
//     return 1;
// }
// fn num_rows(_: *ui.Table.Model.Handler, _: *ui.Table.Model) callconv(.C) c_int {
//     return 1;
// }
// fn col_type(_: *ui.Table.Model.Handler, _: *ui.Table.Model, _: c_int) callconv(.C) ui.Table.Value.Type {
//     return .Image;
// }
// fn cell_value(_: *ui.Table.Model.Handler, _: *ui.Table.Model, _: c_int, _: c_int) callconv(.C) ?*ui.Table.Value {
//     var stream_source = std.io.StreamSource{ .const_buffer = std.io.fixedBufferStream(header_png) };
//     const png = zigimg.png.PNG.readImage(std.heap.page_allocator, &stream_source) catch return null;

//     const width = 300;
//     const height = 180;

//     if (ui.Image.New(width, height)) |img| {
//         img.Append(@ptrCast(@constCast(png.rawBytes()[0..])), width, height, width * 4);
//         if (ui.Table.Value.New(.{ .Image = img })) |value| {
//             return value;
//         } else |_| {
//             return null;
//         }
//     } else |_| {
//         return null;
//     }
// }
// fn set_cell_value(_: *ui.Table.Model.Handler, _: *ui.Table.Model, _: c_int, _: c_int, _: ?*const ui.Table.Value) callconv(.C) void {}

pub fn on_closing(_: *ui.Window, _: ?*void) ui.Window.ClosingAction {
    ui.Quit();
    return .should_close;
}

pub fn on_path_changed(_: *ui.Entry, app_opt: ?*App) void {
    const app = app_opt orelse @panic("Null userdata pointer");
    check_intall_path_empty(app);
}

fn check_intall_path_empty(app: *App) void {
    if (std.mem.eql(u8, "", std.mem.span(app.install_path_entry.Text()))) {
        app.install_btn.as_control().Disable();
    } else {
        app.install_btn.as_control().Enable();
    }
}

fn get_folder(_: *ui.Button, app_opt: ?*App) void {
    const app = app_opt orelse @panic("Null userdata pointer");
    if (app.window.OpenFolder()) |folder| {
        app.install_path_entry.SetText(folder);
        check_intall_path_empty(app);
    }
}

fn install_translation(_: *ui.Button, app_opt: ?*App) void {
    const app = app_opt orelse @panic("Null userdata pointer");
    std.debug.print("Installing in [{s}]\n", .{app.install_path_entry.Text()});
    if (data.install_translation(std.mem.span(app.install_path_entry.Text()))) {
        app.window.MsgBox("Zorionak", "Itzulpenaren instalazioa ongi burutu da.\nEskerrik asko");
    } else |err| {
        app.window.MsgBoxError("Instalatzerakoan errorea", "Erroreren bat egon da itzulpena instalatzerakoan. Exekutatu instalatzailea komando lerroan eta ikusi zein errore izan den.");
        std.debug.print("Instalatzerakoan errorea: {}\n", .{err});
    }
}
