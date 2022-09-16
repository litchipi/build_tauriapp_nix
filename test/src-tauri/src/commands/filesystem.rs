use crate::errors::Errcode;
use crate::state::AppState;

#[tauri::command]
pub async fn write_state<R: tauri::Runtime>(
    state: tauri::State<'_, AppState>,
    app: tauri::AppHandle<R>,
) -> Result<(), Errcode> {
    let app_dir = app
        .path_resolver()
        .app_dir()
        .expect("failed to get app dir");
    let report_path = app_dir.join("state.bin");

    std::fs::write(
        &report_path,
        bincode::serialize(state.inner()).map_err(Errcode::StateSerialization)?,
    )
    .map_err(Errcode::WriteState)?;
    Ok(())
}
