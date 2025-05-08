extends Component
class_name ToggleComponent

signal toggled_groups_changed

@export var toggled_groups: Array[ToggledGroup]:
	set(value):
		toggled_groups = value
		toggled_groups_changed.emit()

func _ready() -> void:
	super()
	if get_parent() is OrbInteractable:
		parent.pressed.connect(toggle)
	else:
		parent.body_entered.connect(toggle)

func toggle(_player: Node):
	for toggled_group in toggled_groups:
		var group = toggled_group.group
		var state = toggled_group.state
		var skip_deleted := func(object):
			return not object.is_in_group("deleted")
		var enable := func(object):
			object.show()
			object.process_mode = PROCESS_MODE_INHERIT
		var disable := func(object):
			object.hide()
			object.process_mode = PROCESS_MODE_DISABLED
		var objects_in_group := get_tree().get_nodes_in_group(group).filter(skip_deleted)
		if state == ToggledGroup.ToggleState.ON:
			objects_in_group.map(enable)
		elif state == ToggledGroup.ToggleState.OFF:
			objects_in_group.map(disable)
		elif state == ToggledGroup.ToggleState.FLIP:
			for object in objects_in_group:
				if object.process_mode == PROCESS_MODE_INHERIT: # If it is toggled on
					object.set_deferred("process_mode", PROCESS_MODE_DISABLED)
					object.hide()
				elif object.process_mode == PROCESS_MODE_DISABLED: # If it is toggled off
					object.set_deferred("process_mode", PROCESS_MODE_INHERIT)
					object.show()
