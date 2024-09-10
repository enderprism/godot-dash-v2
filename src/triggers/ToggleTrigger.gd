@tool
extends Node2D
class_name ToggleTrigger

@export var toggled_groups: Array[ToggledGroup]:
	set(value):
		toggled_groups = value
		update_texture()

var base: TriggerBase

var _toggle: ObjectToggle

func _ready() -> void:
	TriggerSetup.setup(self, false, false)
	_toggle = get_node_or_null("Toggle")
	if _toggle == null:
		_toggle = ObjectToggle.new()
		_toggle.name = "Toggle"
		add_child(_toggle)
		TriggerSetup.set_child_owner(self, _toggle)
	base.sprite.texture = preload("res://assets/textures/triggers/ToggleMultipleGroups.svg")

func _physics_process(_delta: float) -> void:
	if visible:
		update_texture()

func start(_body: Node2D) -> void:
	_toggle._toggle(toggled_groups)

func update_texture() -> void:
	if toggled_groups.size() == 1 and toggled_groups[0] != null:
		match toggled_groups[0].state: 
			ObjectToggle.ToggleState.ON:
				base.sprite.texture = preload("res://assets/textures/triggers/ToggleOn.svg")
			ObjectToggle.ToggleState.OFF:
				base.sprite.texture = preload("res://assets/textures/triggers/ToggleOff.svg")
			ObjectToggle.ToggleState.FLIP:
				base.sprite.texture = preload("res://assets/textures/triggers/ToggleFlip.svg")
	else:
		base.sprite.texture = preload("res://assets/textures/triggers/ToggleMultipleGroups.svg")