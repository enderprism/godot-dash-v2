extends Node2D

class_name GroundObject

const LERP_FACTOR: float = 0.5

@export var DEFAULT_Y: float
@export_range(-1, 1, 2) var distance_multiplier: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_reset_y()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if LevelManager.player_camera != null:
		var global_position_rotated: Vector2 = global_position.rotated(-LevelManager.player._gameplay_rotation)
		if LevelManager.player_camera._freefly:
			global_position_rotated.y = lerpf(
				global_position_rotated.y,
				DEFAULT_Y,
				LERP_FACTOR
			)
		else:
			global_position_rotated.y = lerpf(
				global_position_rotated.y,
				(distance_multiplier * GroundData.distance) / (LevelManager.player_camera.zoom.y/PlayerCamera.DEFAULT_ZOOM.y) + GroundData.center.rotated(-LevelManager.player._gameplay_rotation).y - GroundData.offset,
				LERP_FACTOR
			)
		global_position = global_position_rotated.rotated(LevelManager.player._gameplay_rotation)
		rotation = LevelManager.player._gameplay_rotation

func _reset_y() -> void:
	rotation = 0