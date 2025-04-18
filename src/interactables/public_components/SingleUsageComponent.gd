extends Component
class_name SingleUsageComponent

var enabled := false


func _ready() -> void:
	super()
	enabled = parent.single_usage
	if enabled:
		if parent is OrbInteractable:
			parent.pressed.connect(disable)
		else:
			parent.body_entered.connect(disable)


func disable(_body: Node2D) -> void:
	parent.set_deferred("monitorable", false)
	parent.set_deferred("monitoring", false)
	if parent is TriggerBase:
		parent.set_deferred("process_mode", PROCESS_MODE_DISABLED)
