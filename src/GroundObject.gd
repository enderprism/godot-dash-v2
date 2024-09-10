extends Node2D

class_name GroundObject

const LERP_FACTOR: float = 0.5

@export var DEFAULT_Y: float
@export_enum("Up:-1", "Down:1") var ground_position: int = 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if LevelManager.player_camera != null:
		var zoom_factor: Vector2 = PlayerCamera.DEFAULT_ZOOM/LevelManager.player_camera.zoom
		# var zoom_factor := Vector2.ONE
		var global_position_rotated: Vector2 = global_position.rotated(LevelManager.player.gameplay_rotation)
		if LevelManager.player_camera._freefly:
			global_position_rotated = global_position_rotated.lerp(
				Vector2(global_position_rotated.x, DEFAULT_Y),
				LERP_FACTOR
			)
		else:
			global_position_rotated = global_position_rotated.lerp(
				Vector2(
					GroundData.center.x,
					(ground_position * GroundData.distance) \
						* zoom_factor.y \
						+ GroundData.center.y - GroundData.offset
				),
				LERP_FACTOR
			)
		global_position = global_position_rotated.rotated(-LevelManager.player.gameplay_rotation)

## Sync the rotation with P1's [member Player.gameplay_rotation] on gamemode change.
func _sync_rotation(new_gameplay_rotation: float) -> void:
	rotation = new_gameplay_rotation