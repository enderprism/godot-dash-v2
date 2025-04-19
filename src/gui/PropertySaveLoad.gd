@tool
extends Node
class_name PropertySaveLoad

@export var config_property: StringName
@onready var parent := get_parent() as Property


func _ready() -> void:
	parent.value_changed.connect(save)
	if config_property in Config.config:
		parent.call_deferred("set_value", Config.config.get(config_property))


func save(value: Variant) -> void:
	Config.config.set(config_property, value)
	Config.config.save()
