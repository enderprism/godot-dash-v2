@tool extends Node
class_name BlockPaletteRef

@export var type: EditorSelectionCollider.Type:
	set(value):
		type = value
		notify_property_list_changed()
@export var id: int
@export var object: PackedScene
@export var trigger_script: Script

func _validate_property(property: Dictionary) -> void:
	if property.name == "object" and type == EditorSelectionCollider.Type.TRIGGER:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "trigger_script" and type != EditorSelectionCollider.Type.TRIGGER:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _ready() -> void:
	if type == EditorSelectionCollider.Type.TRIGGER:
		id = hash(trigger_script)