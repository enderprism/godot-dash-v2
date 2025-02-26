@tool
extends Node2D
class_name ToggleTrigger

var base: TriggerBase

var _toggle: ToggleComponent

func _ready() -> void:
	TriggerSetup.setup(self, TriggerSetup.NONE)
	_toggle = get_node_or_null("ToggleComponent")
	if _toggle == null:
		_toggle = ToggleComponent.new()
		_toggle.name = "ToggleComponent"
		add_child(_toggle)
		NodeUtils.set_child_owner(self, _toggle)
	if not _toggle.is_connected("toggled_groups_changed", update_texture):
		_toggle.toggled_groups_changed.connect(update_texture)
	base.sprite.texture = preload("res://assets/textures/triggers/ToggleMultipleGroups.svg")

func _physics_process(_delta: float) -> void:
	if visible:
		update_texture()

func start(_body: Node2D) -> void:
	_toggle.toggle(self)

func update_texture() -> void:
	if _toggle.toggled_groups.size() == 1 and _toggle.toggled_groups[0] != null:
		match _toggle.toggled_groups[0].state: 
			ToggledGroup.ToggleState.ON:
				base.sprite.texture = preload("res://assets/textures/triggers/ToggleOn.svg")
			ToggledGroup.ToggleState.OFF:
				base.sprite.texture = preload("res://assets/textures/triggers/ToggleOff.svg")
			ToggledGroup.ToggleState.FLIP:
				base.sprite.texture = preload("res://assets/textures/triggers/ToggleFlip.svg")
	else:
		base.sprite.texture = preload("res://assets/textures/triggers/ToggleMultipleGroups.svg")