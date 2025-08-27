extends Component
class_name TargetGroupComponent

signal changed(target_group: String)

@export var target_group: String:
	set(value):
		target_group = value
		changed.emit(value)
