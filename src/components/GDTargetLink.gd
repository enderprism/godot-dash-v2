@tool
extends Line2D

class_name GDTargetLink

var _target: Node2D

func _ready() -> void:
	z_index = -50

func _process(_delta: float) -> void:
	if _target == null:
		clear_points()
		return
	if get_point_position(1) != _target.global_position:
		clear_points()
		add_point(to_local(_target.global_position), 0)
		add_point(Vector2.ZERO, 1)
	elif get_point_count() > 2:
		clear_points()
