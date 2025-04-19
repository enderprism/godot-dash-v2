@tool
extends Node
class_name PropertySaveLoad

@export var config_property: StringName

@onready var parent := get_parent() as Property

var type: Property.Type


func _ready() -> void:
	parent.value_changed.connect(save)
	type = parent.type
	if Config.config.get(config_property) != null:
		parent.call_deferred("set_value", Config.config.get(config_property), type)


func save(value: Variant) -> void:
	Config.config.set(config_property, value)
	Config.config.save()
