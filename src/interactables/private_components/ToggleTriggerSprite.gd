extends Sprite2D

@export var toggle_component: ToggleComponent


func _process(_delta: float) -> void:
	if not visible:
		return
	if toggle_component.toggled_groups.size() == 1 and toggle_component.toggled_groups[0] != null:
		match toggle_component.toggled_groups[0].state: 
			ToggledGroup.ToggleState.ON:
				texture = preload("res://assets/textures/triggers/ToggleOn.svg")
			ToggledGroup.ToggleState.OFF:
				texture = preload("res://assets/textures/triggers/ToggleOff.svg")
			ToggledGroup.ToggleState.FLIP:
				texture = preload("res://assets/textures/triggers/ToggleFlip.svg")
	else:
		texture = preload("res://assets/textures/triggers/ToggleMultipleGroups.svg")

