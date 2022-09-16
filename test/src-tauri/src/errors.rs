#[derive(Debug)]
pub enum Errcode {
    WriteState(std::io::Error),
    StateSerialization(Box<bincode::ErrorKind>),
}

impl From<Errcode> for tauri::InvokeError {
    fn from(e: Errcode) -> Self {
        tauri::InvokeError::from(format!("{:?}", e))
    }
}
