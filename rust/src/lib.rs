use godot::prelude::*;
mod gui;

struct MyExtension;

#[gdextension]
unsafe impl ExtensionLibrary for MyExtension {}
