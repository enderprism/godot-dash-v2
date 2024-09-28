@tool extends Resource

class_name ToggledGroup

enum ToggleState {
	ON,
	OFF,
	FLIP,
}

@export var group: StringName
@export var state: ToggleState
