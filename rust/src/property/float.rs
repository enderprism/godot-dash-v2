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
    #[init(val = OnReady::manual())]
    label: OnReady<Gd<Label>>,
    #[init(val = OnReady::manual())]
    input: OnReady<Gd<SpinBox>>,
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
        self.label.init(label);
        self.input.init(input);
        self.signals().renamed().connect_self(Self::refresh);
    }
}

expose_property!(FloatProperty, f64);
impl Property<f64> for FloatProperty {
    fn set_value(&mut self, value: f64) {
        self.input.set_value_no_signal(value);
        self.signals().value_changed().emit(value);
    }
    fn get_value(&self) -> f64 {
        self.input.get_value()
    }
    fn reset(&mut self) {
        self.input.set_value_no_signal(self.default);
    }
    fn refresh(&mut self) {
        let text = self.base().get_name();
        self.label.set_text(text.arg());
        if Engine::singleton().is_editor_hint() {
            self.reset();
        }
    }
    fn set_input_state(&mut self, enabled: bool) {
        self.input.set_editable(enabled);
    }
}
