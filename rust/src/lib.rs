//! DoomForge Rust core, reused from the original Tauri app and exposed to
//! Flutter via flutter_rust_bridge.

pub mod error;

pub mod domain;
pub mod services;

// Flatten domain/services to the crate root so the modules' internal
// `crate::models`, `crate::scan`, `crate::net`, … paths keep resolving.
pub use domain::{
    conflicts, engine, iwad, launch, load_order, logs, models, profile, recommend, report, scan,
    snapshots, stability,
};
pub use services::{ai, net};

pub mod api;
mod frb_generated;
