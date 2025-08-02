@tool
extends Resource
class_name SpawnedGroup


@export var path: NodePath:
	set(value):
		path = value
		emit_changed()
@export_range(0.0, 1.0, 0.01, "suffix:s") var time: float

var loop_idx: int
