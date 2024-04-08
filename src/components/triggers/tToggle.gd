@tool
class_name tToggle extends Node2D

@export var _toggled_groups: Array[gToggledGroup]:
	set(value):
		_toggled_groups = value
		_update_texture()

var _base: tBase
var _setup: tSetup

func _ready() -> void:
	_setup = tSetup.new(self, false, false)
	_base._sprite.texture = preload("res://assets/textures/triggers/ToggleMultipleGroups.svg")

func _start(_body: Node2D) -> void:
	var toggle = GDToggle.new()
	toggle._toggle(self, _toggled_groups)
	toggle.queue_free()

func _update_texture() -> void:
	if _toggled_groups.size() == 1 and _toggled_groups[0] != null:
		match _toggled_groups[0].state: 
			GDToggle.ToggleState.ON:
				_base._sprite.texture = preload("res://assets/textures/triggers/ToggleOn.svg")
			GDToggle.ToggleState.OFF:
				_base._sprite.texture = preload("res://assets/textures/triggers/ToggleOff.svg")
			GDToggle.ToggleState.FLIP:
				_base._sprite.texture = preload("res://assets/textures/triggers/ToggleFlip.svg")
	else:
		_base._sprite.texture = preload("res://assets/textures/triggers/ToggleMultipleGroups.svg")

func _process(_delta: float) -> void:
	if visible:
		_update_texture()
