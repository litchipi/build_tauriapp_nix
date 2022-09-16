use crate::state::AppState;

mod filesystem;

#[tauri::command]
fn increase_counter(state: tauri::State<AppState>) {
    *state.inner().counter.lock().unwrap() += 1;
}

#[tauri::command]
fn decrease_counter(state: tauri::State<AppState>) {
    *state.inner().counter.lock().unwrap() -= 1;
}

pub fn setup<R: tauri::Runtime>(builder: tauri::Builder<R>) -> tauri::Builder<R> {
    builder.invoke_handler(tauri::generate_handler![
        filesystem::write_state,
        increase_counter,
        decrease_counter,
    ])
}
