extends Node
class_name GravityTextureFlip

@onready var sprite := get_parent().get_node(^"Sprite") as Sprite2D

func _process(_delta: float) -> void:
	sprite.flip_v = LevelManager.player.gravity_flip < 0
