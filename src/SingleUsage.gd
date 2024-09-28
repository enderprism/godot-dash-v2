extends Node
class_name SingleUsageComponent

@onready var _parent := get_parent() as Area2D
var _enabled := false


func _ready() -> void:
	_enabled = _parent.single_usage
	# Doesn't register itself if the parent is an Interactable because it's a private component
	# aka it only interacts with its parent.
	if _enabled:
		if _parent is OrbInteractable:
			_parent.pressed.connect(disable)
		else:
			_parent.body_entered.connect(disable)


func disable(_body: Node2D) -> void:
	_parent.set_deferred("monitorable", false)
	_parent.set_deferred("monitoring", false)
	if _parent is TriggerBase:
		_parent.set_deferred("process_mode", PROCESS_MODE_DISABLED)