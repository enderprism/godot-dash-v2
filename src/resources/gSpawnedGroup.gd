@tool
extends Resource
class_name gSpawnedGroup


@export var path: NodePath:
	set(value):
		path = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var time: float

var used_in_loop: int
