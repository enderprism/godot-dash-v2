extends Node
class_name PathFollowSpeed

func _ready() -> void:
	var parent := get_parent() as FireDashComponent
	parent.path = self
