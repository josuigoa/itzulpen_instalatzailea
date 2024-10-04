const std = @import("std");
const ui = @import("ui");
const zigimg = @import("zigimg");
const utils = @import("utils");
const builtin = @import("builtin");
const installation_finder = @import("installation_finder.zig");
const data = @import("data/installer.zig");

pub const App = struct {
    window: *ui.Window,
    install_path_entry: *ui.Entry,
    select_language: bool,
    language_combobox: *ui.Combobox,
    install_btn: *ui.Button,
};

pub fn main() !void {
    comptime data.comptime_checks();

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

    const window_width = 400;
    const window_height = 160;

    const main_window = try ui.Window.New("Itzulpen instalatzailea", window_width, window_height, .hide_menubar);
    main_window.SetMargined(true);
    main_window.as_control().Show();
    main_window.OnClosing(void, on_closing, null);

    const v_box = try ui.Box.New(.Vertical);
    v_box.SetPadded(true);
    main_window.SetChild(v_box.as_control());

    const game_name = data.get_game_names()[0];

    const installer_text: utils.string = if (std.mem.eql(u8, "", game_path))
        "Ez da instalaziorik aurkitu, bilatu zuk mesedez."
    else
        "Ondorengo bidean aurkitu da instalazioa, egiaztatu zuzena ote den.";
    const label_text = try utils.concat(&.{ "[", game_name, "] jokoa euskaratzeko instalatzailea\n", installer_text });
    const label = try ui.Label.New(@ptrCast(label_text));
    v_box.Append(label.as_control(), .dont_stretch);

    const bide_box = try ui.Box.New(.Horizontal);
    bide_box.SetPadded(true);
    v_box.Append(bide_box.as_control(), .dont_stretch);

    const install_path_entry = try ui.Entry.New(ui.Entry.Type.Entry);
    bide_box.Append(install_path_entry.as_control(), .stretch);

    const find_btn = try ui.Button.New("Bilatu");
    bide_box.Append(find_btn.as_control(), .dont_stretch);

    const language_combobox = try ui.Combobox.New();
    var select_language = false;
    if (data.get_languages()) |languages| {
        select_language = true;
        const combo_label = try ui.Label.New("Ordezkatzeko hizkuntza");
        v_box.Append(combo_label.as_control(), .dont_stretch);
        for (languages) |lang| {
            if (!std.mem.eql(u8, lang, ""))
                language_combobox.Append(lang);
        }
        v_box.Append(language_combobox.as_control(), .dont_stretch);
    }

    const install_btn = try ui.Button.New("Instalatu");
    v_box.Append(install_btn.as_control(), .dont_stretch);

    install_path_entry.SetText(@ptrCast(game_path));

    var app = App{
        .window = main_window,
        .install_path_entry = install_path_entry,
        .select_language = select_language,
        .language_combobox = language_combobox,
        .install_btn = install_btn,
    };

    check_intall_path_empty(&app);
    install_path_entry.OnChanged(App, on_path_changed, &app);
    find_btn.OnClicked(App, get_folder, &app);
    install_btn.OnClicked(App, install_translation, &app);

    ui.Main();
}

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

    const language_index = @as(usize, @intCast(app.language_combobox.Selected()));
    // ez bada hizkuntzarik aukeratu, combobox-ak -1 itzuliko du.
    // Baina usize-era cast egitean, usize-k ezin baitu negatiborik adierazi, zenbaki altu bat ematen du
    if (app.select_language and language_index > 2) {
        app.window.MsgBoxError("Aukeratu hizkuntza", "Aukeratu zein hizkuntza ordezkatu nahi duzun, mesedez.");
        return;
    }

    if (data.install_translation(std.mem.span(app.install_path_entry.Text()), @as(usize, language_index))) |opt_installer_response| {
        if (opt_installer_response) |installer_response| {
            app.window.MsgBox(installer_response.title, installer_response.body);
        } else {
            app.window.MsgBox("Zorionak", "Itzulpenaren instalazioa ongi burutu da.\nEskerrik asko");
        }
    } else |err| {
        app.window.MsgBoxError("Instalatzerakoan errorea", "Erroreren bat egon da itzulpena instalatzerakoan. Exekutatu instalatzailea komando lerroan eta ikusi zein errore izan den.");
        std.debug.print("Instalatzerakoan errorea: {}\n", .{err});
    }
}
