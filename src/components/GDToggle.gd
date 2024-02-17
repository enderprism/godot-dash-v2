class_name GDToggle extends Node2D

enum ToggleState {
	ON,
	OFF,
	FLIP,
}

func _toggle(instancer: Node, toggled_groups):
	for toggled_group in toggled_groups:
		var group = instancer.get_node(toggled_group.group)
		var state = toggled_group.state
		if state == ToggleState.FLIP:
			if group.process_mode == PROCESS_MODE_INHERIT: # If it is toggled on
				state = ToggleState.OFF
			elif group.process_mode == PROCESS_MODE_DISABLED: # If it is toggled off
				state = ToggleState.ON
		match state:
			ToggleState.ON:
				group.set_deferred("process_mode", PROCESS_MODE_INHERIT)
				group.show()
			ToggleState.OFF:
				group.set_deferred("process_mode", PROCESS_MODE_DISABLED)
				group.hide()
