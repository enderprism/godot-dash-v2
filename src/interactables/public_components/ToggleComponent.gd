extends Component
class_name ToggleComponent

signal toggled_groups_changed

@export var toggled_groups: Array[ToggledGroup]:
	set(value):
		toggled_groups = value
		toggled_groups_changed.emit()

func _ready() -> void:
	if get_parent() is OrbInteractable:
		parent.pressed.connect(toggle)
	elif get_parent().has_node("TriggerBase"):
		get_parent().base.body_entered.connect(toggle)

func toggle(_player: Node):
	for toggled_group in toggled_groups:
		var group = toggled_group.group
		var state = toggled_group.state
		if state == ToggledGroup.ToggleState.ON:
				group.set_deferred_thread_group("process_mode", PROCESS_MODE_INHERIT)
				group.call_deferred_thread_group("show")
		elif state == ToggledGroup.ToggleState.OFF:
				group.set_deferred_thread_group("process_mode", PROCESS_MODE_DISABLED)
				group.call_deferred_thread_group("hide")
		elif state == ToggledGroup.ToggleState.FLIP:
			for object in get_tree().get_nodes_in_group(group):
				if object.process_mode == PROCESS_MODE_INHERIT: # If it is toggled on
					object.set_deferred("process_mode", PROCESS_MODE_DISABLED)
					object.hide()
				elif object.process_mode == PROCESS_MODE_DISABLED: # If it is toggled off
					object.set_deferred("process_mode", PROCESS_MODE_INHERIT)
					object.show()
