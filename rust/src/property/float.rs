use godot::classes::control::SizeFlags;
use godot::classes::{Control, Engine, HBoxContainer, IHBoxContainer, Label, SpinBox};
use godot::prelude::*;

use super::Property;
use crate::expose_property;

#[derive(GodotClass)]
#[class(init, base=HBoxContainer, tool)]
struct FloatProperty {
    // Exports
    #[export]
    default: f64,
    #[export]
    min: f64,
    #[export]
    max: f64,
    #[export]
    step: f64,
    #[export]
    rounded: bool,
    #[export]
    or_greater: bool,
    #[export]
    or_less: bool,
    #[export]
    prefix: GString,
    #[export]
    suffix: GString,

    // Members
    label: Option<Gd<Label>>,
    input: Option<Gd<SpinBox>>,
    base: Base<HBoxContainer>,
}

#[godot_api]
impl IHBoxContainer for FloatProperty {
    fn ready(&mut self) {
        let mut label = Label::new_alloc();
        let mut spacer = Control::new_alloc();
        let input = SpinBox::new_alloc();
        let text = self.base().get_name();
        label.set_text(text.arg());
        spacer.set_h_size_flags(SizeFlags::EXPAND);
        self.base_mut().add_child(&label.clone().upcast::<Node>());
        self.base_mut().add_child(&spacer.upcast::<Node>());
        self.base_mut().add_child(&input.clone().upcast::<Node>());
        self.label = Some(label);
        self.input = Some(input);
        self.signals().renamed().connect_self(Self::refresh);
    }
}

expose_property!(FloatProperty, f64);
impl Property<f64> for FloatProperty {
    fn set_value(&mut self, value: f64) {
        match &mut self.input {
            Some(input) => input.set_value_no_signal(value),
            None => godot_error!("Input field is not initalized"),
        }
        self.signals().value_changed().emit(value);
    }
    fn get_value(&self) -> f64 {
        match &self.input {
            Some(input) => input.get_value(),
            None => {
                godot_error!("Input field is not initalized");
                f64::NAN // Result<T, E> doesn't exist in GDScript
            }
        }
    }
    fn reset(&mut self) {
        match &mut self.input {
            Some(input) => input.set_value_no_signal(self.default),
            None => godot_error!("Input field is not initalized"),
        }
    }
    fn refresh(&mut self) {
        let text = self.base().get_name();
        match &mut self.label {
            Some(label) => label.set_text(text.arg()),
            None => godot_error!("Label is not initialized"),
        }
        if Engine::singleton().is_editor_hint() {
            self.reset();
        }
    }
    fn set_input_state(&mut self, enabled: bool) {
        match &mut self.input {
            Some(input) => input.set_editable(enabled),
            None => godot_error!("Input field is not initalized"),
        }
    }
}
