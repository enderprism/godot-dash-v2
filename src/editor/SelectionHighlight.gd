extends Node
class_name SelectionHighlight

var original_modulate: Color

@onready var parent := get_parent() as CanvasItem

func _ready() -> void:
	original_modulate = parent.modulate
	parent.modulate = Color.GREEN

func _exit_tree() -> void:
	parent.modulate = original_modulate

func _enter_tree() -> void:
	name = "SelectionHighlight"
	owner = get_parent()