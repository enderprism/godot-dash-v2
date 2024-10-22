extends Node
class_name GUIInputValueReset

@export var property := &""
var default_value: Variant
@onready var parent := get_parent() as Control


func _ready() -> void:
	default_value = parent.get(property)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"gui_input_reset_default") and parent.get_rect().has_point(parent.get_parent().get_local_mouse_position()):
		parent.set(property, default_value)