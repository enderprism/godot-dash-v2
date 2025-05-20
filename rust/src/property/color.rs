use godot::classes::control::SizeFlags;
use godot::classes::{ColorPickerButton, Control, Engine, HBoxContainer, IHBoxContainer, Label};
use godot::prelude::*;

use super::Property;
use crate::expose_property;

#[derive(GodotClass)]
#[class(init, base=HBoxContainer, tool)]
struct ColorProperty {
    // Exports
    #[export]
    default: Color,

    // Members
    #[init(val = OnReady::manual())]
    label: OnReady<Gd<Label>>,
    #[init(val = OnReady::manual())]
    input: OnReady<Gd<ColorPickerButton>>,
    base: Base<HBoxContainer>,
}

#[godot_api]
impl IHBoxContainer for ColorProperty {
    fn ready(&mut self) {
        let mut label = Label::new_alloc();
        let mut spacer = Control::new_alloc();
        let mut input = ColorPickerButton::new_alloc();
        let text = self.base().get_name();
        label.set_text(text.arg());
        spacer.set_h_size_flags(SizeFlags::EXPAND);
        input
            .signals()
            .color_changed()
            .connect_obj(&self.to_gd(), |s: &mut Self, new_value| {
                s.signals().value_changed().emit(new_value);
            });
        self.base_mut().add_child(&label.clone().upcast::<Node>());
        self.base_mut().add_child(&spacer.upcast::<Node>());
        self.base_mut().add_child(&input.clone().upcast::<Node>());
        self.label.init(label);
        self.input.init(input);
        self.signals().renamed().connect_self(Self::refresh);
        self.refresh();
    }
}

expose_property!(ColorProperty, Color);
impl Property<Color> for ColorProperty {
    fn set_value(&mut self, value: Color) {
        self.input.set_pick_color(value);
        self.signals().value_changed().emit(value);
    }
    fn get_value(&self) -> Color {
        self.input.get_pick_color()
    }
    fn reset(&mut self) {
        self.input.set_pick_color(self.default);
    }
    fn refresh(&mut self) {
        self.base_mut()
            .set_custom_minimum_size(Vector2::new(0.0, 32.0));
        // Label
        let text = self.base().get_name();
        self.label.set_text(text.arg());
        // Input
        self.input.set_custom_minimum_size(Vector2::new(100.0, 0.0));
        // Editor refresh
        if Engine::singleton().is_editor_hint() {
            self.reset();
        }
    }
    fn set_input_state(&mut self, enabled: bool) {
        self.input.set_disabled(!enabled);
    }
}
