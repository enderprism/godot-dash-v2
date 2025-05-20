extends Control

func _ready() -> void:
	var float_property := $FloatProperty as FloatProperty
	float_property.set_value(5.0)

func _on_float_property_value_changed(new_value:float) -> void:
	print_debug(new_value)

