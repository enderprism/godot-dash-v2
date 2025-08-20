extends Marker
class_name SingleUsageComponent


func _ready() -> void:
	super()
	parent.interacted.connect(disable)


func disable(_body: Node2D) -> void:
	parent.set_deferred("monitorable", false)
	parent.set_deferred("monitoring", false)
	if parent is TriggerBase:
		parent.set_deferred("process_mode", PROCESS_MODE_DISABLED)
