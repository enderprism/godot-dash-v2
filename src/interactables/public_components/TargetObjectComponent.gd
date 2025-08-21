extends Component
class_name TargetObjectComponent

signal target_changed(new_target: Node2D)

@export var target: Node2D:
	set(value):
		target = value
		target_changed.emit(value)
