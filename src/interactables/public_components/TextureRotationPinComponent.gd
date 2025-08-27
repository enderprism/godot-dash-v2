@tool
extends Component
class_name TextureRotationPinComponent

@export var pinned: CanvasItem
@export var pin_to_gameplay_rotation := false
@export var sprite_scale := Vector2.ONE


func _process(_delta: float) -> void:
	if pinned == null:
		return
	if not Engine.is_editor_hint() and LevelManager.player_camera != null:
		if pin_to_gameplay_rotation:
			pinned.global_rotation = LevelManager.player.gameplay_rotation
		else:
			pinned.global_rotation = LevelManager.player_camera.rotation
	else:
		pinned.global_rotation = 0.0
	pinned.global_scale.x = abs(parent.scale.x)
	pinned.global_scale.y = abs(parent.scale.y)
	pinned.global_scale *= sprite_scale
