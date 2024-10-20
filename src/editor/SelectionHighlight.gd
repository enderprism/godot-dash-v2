extends Node

var original_modulate: Color

@onready var parent := get_parent() as CanvasItem

func _ready() -> void:
	original_modulate = parent.modulate
	parent.modulate = Color.GREEN

func _exit_tree() -> void:
	parent.modulate = original_modulate