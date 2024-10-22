extends Node
class_name ViewportSizeValue

@export var property: StringName
@onready var parent := get_parent() as Node
var viewport_size: Vector2

func _ready() -> void:
	viewport_size = parent.get_viewport_rect().size
	if parent.get(property) == null or parent.get(property) == Vector2.ZERO: # Needs to run after SaveLoadConfigValue
		parent.set(property, viewport_size)