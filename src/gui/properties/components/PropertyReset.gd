extends Node
class_name PropertyReset

@onready var parent := get_parent() as AbstractProperty
var input: Control

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"gui_input_reset_default") \
			and input.get_rect().has_point(parent.get_local_mouse_position()):
		parent.reset()

func set_input(value: Control) -> PropertyReset:
	input = value
	return self
