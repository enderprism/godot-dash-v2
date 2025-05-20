use godot::prelude::*;
mod property;

struct MyExtension;

#[gdextension]
unsafe impl ExtensionLibrary for MyExtension {}
