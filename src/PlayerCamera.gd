extends Camera2D

class_name PlayerCamera

const DEFAULT_ZOOM: Vector2 = Vector2(0.8, 0.8)
const DEFAULT_OFFSET: Vector2 = Vector2(400.0, 0.0)
const DEFAULT_LIMIT_BOTTOM: int = 1080
const MIN_HEIGHT: float = -5500.0
const MAX_HEIGHT: float = 413.0
const MAX_DISTANCE := Vector2(400.0, 200.0)

@export var position_smoothing: Vector2 = Vector2(0.1, 0.1)
@export var offset_smoothing: Vector2 = Vector2(0.125, 0.125)

# I use a fake offset (which modifies the position) instead of a real one because
# it makes the camera static transition weird
var velocity: Vector2
var movement_factor := Vector2.ONE
var offset_factor := Vector2.ONE
var player: Player
var player_distance: Vector2
var position_offset: Vector2
var additional_offset: Vector2
var additional_offset_multiplier := Vector2.ONE
var freefly := true


func _ready() -> void:
	LevelManager.player_camera = self
	player = LevelManager.player


func _physics_process(delta: float) -> void:
	var framerate_compensation := delta * 60.0

	if zoom.y > 1.0:
		limit_bottom = int(DEFAULT_LIMIT_BOTTOM * zoom.y)

	if not LevelManager.level_playing:
		return

	player_distance = player.position - position
	var rotation_local_player_distance := player_distance.rotated(-player.gameplay_rotation)
	var rotation_local_player_position := player.position.rotated(-player.gameplay_rotation)
	var rotation_local_position := position.rotated(-player.gameplay_rotation)
	var rotation_local_offset := position_offset.rotated(-player.gameplay_rotation)

	if LevelManager.platformer:
		if abs(rotation_local_player_distance.x) > (MAX_DISTANCE.x / zoom.x):
			rotation_local_position.x = lerpf(
				rotation_local_position.x,
				lerpf(
					rotation_local_position.x,
					rotation_local_player_position.x - signf(rotation_local_player_distance.x) * (MAX_DISTANCE.x / zoom.x),
					position_smoothing.x * framerate_compensation),
				movement_factor.x)
		rotation_local_offset.x = additional_offset.x
	else:
		rotation_local_position.x = lerpf(
			rotation_local_position.x,
			lerpf(rotation_local_position.x, rotation_local_player_position.x, movement_factor.x),
			movement_factor.x)
		rotation_local_offset.x = lerpf(
			rotation_local_offset.x,
			((DEFAULT_OFFSET.x * player.get_direction() * sign(player.speed_multiplier)) / zoom.x),
			offset_smoothing.x * framerate_compensation
			) * offset_factor.x + additional_offset.x
	if freefly:
		if abs(rotation_local_player_distance.y) > (MAX_DISTANCE.y / zoom.y):
			rotation_local_position.y = lerpf(
				rotation_local_position.y,
				lerpf(
					rotation_local_position.y,
					rotation_local_player_position.y - signf(rotation_local_player_distance.y) * (MAX_DISTANCE.y / zoom.y),
					position_smoothing.y * framerate_compensation),
				movement_factor.y)
	else:
		rotation_local_position.y = lerpf(
			rotation_local_position.y,
			GroundData.center.rotated(-player.gameplay_rotation).y - GroundData.offset,
			position_smoothing.y * framerate_compensation)


	rotation_local_offset.y = lerpf(
		rotation_local_offset.y,
		(DEFAULT_OFFSET.y / zoom.y) * offset_factor.y + additional_offset.y,
		offset_smoothing.y * framerate_compensation)

	# position += rotation_local_velocity.rotated(player.gameplay_rotation)
	position = rotation_local_position.rotated(player.gameplay_rotation)
	position_offset = rotation_local_offset.rotated(player.gameplay_rotation)
	position += position_offset


	position.y = clampf(
			position.y,
			MIN_HEIGHT,
			MAX_HEIGHT)

