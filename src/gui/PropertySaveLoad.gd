@tool
extends Node
class_name PropertySaveLoad

@export var config_property: StringName
@export var property_owner: Node
@onready var parent := get_parent() as Property
var _property_owner: Variant


func _ready() -> void:
	parent.value_changed.connect(save)
	load_value()

func load_value() -> void:
	if property_owner != null:
		_property_owner = property_owner
	else:
		_property_owner = Config.config
	if config_property in _property_owner:
		parent.call_deferred("set_value", _property_owner.get(config_property))

func save(value: Variant) -> void:
	if property_owner != null:
		_property_owner = property_owner
	else:
		_property_owner = Config.config
	_property_owner.set(config_property, value)
	if _property_owner == Config.config:
		Config.config.save()
