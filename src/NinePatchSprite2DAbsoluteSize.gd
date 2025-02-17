@tool
extends Node
class_name NinePatchSprite2DAbsoluteSize

@export var nine_patch_sprite: NinePatchSprite2D
@onready var parent := get_parent() as Node

func _physics_process(_delta: float) -> void:
	nine_patch_sprite.global_scale = Vector2.ONE/4
	nine_patch_sprite.size = abs(parent.global_scale) * 512
