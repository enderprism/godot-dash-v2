@tool
extends Node
class_name SaveLoadConfigValue

@export var config_property: StringName
@export var property: StringName
@export var save_signal: StringName
@onready var parent := get_parent() as Node

func _ready() -> void:
	get_parent().connect(save_signal, save)
	if Config.config.get(config_property) != null:
		parent.set(property, Config.config.get(config_property))

func save(value: Variant) -> void:
	Config.config.set(config_property, value)
	Config.config.save()