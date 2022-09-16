use serde::{Deserialize, Serialize};
use std::sync::Mutex;

#[derive(Serialize, Deserialize)]
pub struct AppState {
    pub counter: Mutex<u64>,
}

pub fn setup<R: tauri::Runtime>(builder: tauri::Builder<R>) -> tauri::Builder<R> {
    builder.manage(AppState {
        counter: Mutex::new(0),
    })
}
