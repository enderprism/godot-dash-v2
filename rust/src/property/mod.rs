pub mod float;

trait Property<T> {
    fn set_value(&mut self, value: T);
    fn get_value(&self) -> T;
    fn reset(&mut self);
    fn refresh(&mut self);
    fn set_input_state(&mut self, enabled: bool);
}

#[macro_export]
macro_rules! expose_property {
    ($property_name:ident, $type:ident) => {
        #[godot_api]
        impl $property_name {
            #[signal]
            fn value_changed(new_value: $type);
            #[func(rename = set_value)]
            fn set_value_impl(&mut self, value: $type) {
                self.set_value(value);
            }
            #[func(rename = get_value)]
            fn get_value_impl(&self) -> $type {
                self.get_value()
            }
            #[func(rename = reset)]
            fn reset_impl(&mut self) {
                self.reset();
            }
            #[func(rename = refresh)]
            fn refresh_impl(&mut self) {
                self.refresh();
            }
            #[func(rename = set_input_state)]
            fn set_input_state_impl(&mut self, enabled: bool) {
                self.set_input_state(enabled);
            }
        }
    };
}
