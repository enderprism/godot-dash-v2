use godot::classes::control::SizeFlags;
use godot::classes::{Control, Engine, HBoxContainer, IHBoxContainer, Label, LineEdit};
use godot::prelude::*;

use super::Property;
use crate::expose_property;

#[derive(GodotClass)]
#[class(init, base=HBoxContainer, tool)]
struct StringProperty {
    // Exports
    #[export]
    default: GString,
    #[export]
    placeholder: GString,

    // Members
    #[init(val = OnReady::manual())]
    label: OnReady<Gd<Label>>,
    #[init(val = OnReady::manual())]
    input: OnReady<Gd<LineEdit>>,
    base: Base<HBoxContainer>,
}

#[godot_api]
impl IHBoxContainer for StringProperty {
    fn ready(&mut self) {
        let mut label = Label::new_alloc();
        let mut spacer = Control::new_alloc();
        let mut input = LineEdit::new_alloc();
        let text = self.base().get_name();
        label.set_text(text.arg());
        spacer.set_h_size_flags(SizeFlags::EXPAND);
        input
            .signals()
            .text_submitted()
            .connect_obj(&self.to_gd(), |s: &mut Self, new_value| {
                s.signals().value_changed().emit(&new_value);
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

expose_property!(StringProperty, GString);
impl Property<GString> for StringProperty {
    fn set_value(&mut self, value: GString) {
        self.input.set_text(&value);
        self.signals().value_changed().emit(&value);
    }
    fn get_value(&self) -> GString {
        self.input.get_text()
    }
    fn reset(&mut self) {
        self.input.set_text(&self.default);
    }
    fn refresh(&mut self) {
        // Label
        let text = self.base().get_name();
        self.label.set_text(text.arg());
        // Input
        self.input.set_placeholder(&self.placeholder);
        // Editor refresh
        if Engine::singleton().is_editor_hint() {
            self.reset();
        }
    }
    fn set_input_state(&mut self, enabled: bool) {
        self.input.set_editable(enabled);
    }
}
