use serde::{Serialize, Serializer};

/// Crate-wide error type. Serializes to a plain string so the frontend
/// receives a readable message from a rejected `invoke`.
#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("io error: {0}")]
    Io(#[from] std::io::Error),

    #[error("serialization error: {0}")]
    Serde(#[from] serde_json::Error),

    #[error("zip error: {0}")]
    Zip(#[from] zip::result::ZipError),

    #[error("{0}")]
    Other(String),
}

impl AppError {
    pub fn msg(s: impl Into<String>) -> Self {
        AppError::Other(s.into())
    }
}

impl Serialize for AppError {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&self.to_string())
    }
}

pub type AppResult<T> = Result<T, AppError>;
