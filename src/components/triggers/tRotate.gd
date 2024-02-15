@tool
class_name tRotate extends "res://src/components/triggers/tEasableTrigger.gd"

@export var _use_target: bool:
	set(value):
		_use_target = value
		notify_property_list_changed()

@export var _move_target: NodePath

@export var _move_coordinates: Vector2

func _validate_property(property: Dictionary) -> void:
	if property.name in ["_move_coordinates"] and _use_target:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_move_target"] and not _use_target:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _init() -> void:
	_texture = preload("res://assets/textures/triggers/Rotate.svg")

func _run(_body: Node2D) -> void:
	pass