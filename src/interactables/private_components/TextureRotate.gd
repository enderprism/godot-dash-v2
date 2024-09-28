extends Node
class_name TextureRotate

@export_range(-360.0, 360.0, 0.01, "or_greater", "or_less") var rotation_rate_degrees: float

@onready var sprite := get_parent().get_node(^"Sprite") as Sprite2D

func _process(delta: float) -> void:
	sprite.rotation_degrees += rotation_rate_degrees * delta