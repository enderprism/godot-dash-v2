extends Node
class_name SelectionHighlight

var modulate: Color
var is_duplicate: bool

@onready var parent := get_parent() as CanvasItem

func _ready() -> void:
	modulate = parent.modulate
	parent.modulate = Color.GREEN if not is_duplicate else Color.CYAN

func _exit_tree() -> void:
	if is_queued_for_deletion():
		parent.modulate = modulate

func _enter_tree() -> void:
	name = "SelectionHighlight"
	owner = get_parent()

func _set_duplicate() -> void:
	parent.modulate = Color.CYAN
