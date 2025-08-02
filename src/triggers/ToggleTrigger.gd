@tool
extends Node2D
class_name ToggleTrigger

var base: TriggerBase

var toggle: ToggleComponent

func _ready() -> void:
	TriggerSetup.setup(self, TriggerSetup.NONE)
	toggle = NodeUtils.get_node_or_add(base, "ToggleComponent", ToggleComponent)
	if not toggle.is_connected("toggled_groups_changed", update_texture):
		toggle.toggled_groups_changed.connect(update_texture)
	base.sprite.texture = preload("res://assets/textures/triggers/ToggleMultipleGroups.svg")

func _physics_process(_delta: float) -> void:
	if visible:
		update_texture()

func update_texture() -> void:
	if toggle.toggled_groups.size() == 1 and toggle.toggled_groups[0] != null:
		match toggle.toggled_groups[0].state: 
			ToggledGroup.ToggleState.ON:
				base.sprite.texture = preload("res://assets/textures/triggers/ToggleOn.svg")
			ToggledGroup.ToggleState.OFF:
				base.sprite.texture = preload("res://assets/textures/triggers/ToggleOff.svg")
			ToggledGroup.ToggleState.FLIP:
				base.sprite.texture = preload("res://assets/textures/triggers/ToggleFlip.svg")
	else:
		base.sprite.texture = preload("res://assets/textures/triggers/ToggleMultipleGroups.svg")
