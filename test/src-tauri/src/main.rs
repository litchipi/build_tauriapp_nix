#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

mod commands;
mod errors;
mod state;

fn main() {
    let mut builder = tauri::Builder::default();
    builder = commands::setup(builder);
    builder = state::setup(builder);
    builder
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
