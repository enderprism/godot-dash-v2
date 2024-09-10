@tool
extends Line2D

class_name GDTargetLink

var target: Node2D

var _lock_position_to_parent: bool

func _ready() -> void:
	z_index = -50

func _process(_delta: float) -> void:
	if _lock_position_to_parent: position = Vector2.ZERO
	if target == null:
		clear_points()
		return
	if get_point_position(1) != target.global_position:
		clear_points()
		add_point(to_local(target.global_position), 0)
		add_point(Vector2.ZERO, 1)
	elif get_point_count() > 2:
		clear_points()
	if not Engine.is_editor_hint() and not (LevelManager.in_editor or get_tree().is_debugging_collisions_hint()):
		hide()
