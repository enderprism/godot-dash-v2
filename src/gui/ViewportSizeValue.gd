extends Node
class_name ViewportSizeValue

@onready var parent := get_parent() as Node


func _ready() -> void:
	if parent.value == null or parent.value == Vector2.ZERO: # Needs to run after SaveLoadConfigValue
		parent.value = parent.get_viewport_rect().size