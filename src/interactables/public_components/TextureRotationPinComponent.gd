@tool
extends Component
class_name TextureRotationPin

@export var sprite: Sprite2D
@export var pin_to_gameplay_rotation := false
@export var sprite_scale := Vector2.ONE


func _process(_delta: float) -> void:
	if sprite == null:
		return
	if not Engine.is_editor_hint() and LevelManager.player_camera != null:
		if pin_to_gameplay_rotation:
			sprite.global_rotation = LevelManager.player.gameplay_rotation
		else:
			sprite.global_rotation = LevelManager.player_camera.rotation
	else:
		sprite.global_rotation = 0.0
	sprite.global_scale.x = abs(parent.scale.x)
	sprite.global_scale.y = abs(parent.scale.y)
	sprite.global_scale *= sprite_scale
