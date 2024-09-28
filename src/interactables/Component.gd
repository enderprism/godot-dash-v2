extends Node
class_name Component

@onready var parent := get_parent() as Interactable


func _ready() -> void:
	parent.register_public(self)