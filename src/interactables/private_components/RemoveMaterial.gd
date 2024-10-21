extends Node
class_name RemoveMaterial

@onready var parent := get_parent() as Node2D

func _ready() -> void:
	parent.material = null