@tool
class_name tToggle extends tTriggerBase

@export var _toggled_groups: Array[gToggledGroup]:
	set(value):
		_toggled_groups = value
		_update_texture()

func _run(_body: Node2D) -> void:
	var toggle = GDToggle.new()
	toggle._toggle(self, _toggled_groups)
	toggle.queue_free()

func _update_texture() -> void:
	if _toggled_groups.size() == 1:
		match _toggled_groups[0].state: 
			GDToggle.ToggleState.ON:
				_texture = preload("res://assets/textures/triggers/ToggleOn.svg")
			GDToggle.ToggleState.OFF:
				_texture = preload("res://assets/textures/triggers/ToggleOff.svg")
	else:
		_texture = preload("res://assets/textures/triggers/ToggleMultipleGroups.svg")
	super()

func _process(_delta: float) -> void:
	if visible:
		_update_texture()
