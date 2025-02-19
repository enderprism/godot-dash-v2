extends Camera2D

class_name PlayerCamera

@onready var player: Player = LevelManager.player

const DEFAULT_ZOOM: Vector2 = Vector2(0.8, 0.8)
const MIN_HEIGHT: float = -5500.0
const MAX_HEIGHT: float = 413.0
const MAX_DISTANCE := Vector2(500, 200.0)

var _previous_position: Vector2
var _delta_position: Vector2
var _player_distance: Vector2
var _position_snap: Vector2 = Vector2(0.1, 0.1)
var _offset_snap: Vector2 = Vector2(0.125, 0.125)
var _freefly: bool = true
# I use a fake offset (which modifies the position) instead of a real one because
# it makes the camera static transition weird
var position_offset: Vector2

const DEFAULT_OFFSET: Vector2 = Vector2(400.0, 0.0)
const DEFAULT_LIMIT_BOTTOM: int = 1080

var _static: Vector2i
var additional_offset: Vector2
var additional_offset_multiplier: Vector2 = Vector2.ONE

func _ready() -> void:
	position += DEFAULT_OFFSET
	LevelManager.player_camera = self

func _physics_process(delta: float) -> void:
	if zoom.y > 1.0:
		limit_bottom = int(DEFAULT_LIMIT_BOTTOM * zoom.y)
	var framerate_compensation := delta * 60
	if LevelManager.level_playing:
		_player_distance = player.position - position
		_delta_position = get_screen_center_position() - _previous_position
		_previous_position = get_screen_center_position()

		# TODO make the camera movement rotation-independant
		# I'd love to use Vector2.rotated all over the place but it only works well with deltas, and here I change the position directly.
		# If you find out how to use a position and offset delta instead, make sure to open a PR!
		if LevelManager.level_playing:
			if abs(player.gameplay_rotation_degrees) == 90.0 or abs(player.gameplay_rotation_degrees) == 180.0:
				position_offset.x = lerpf(position_offset.x, DEFAULT_OFFSET.y/zoom.x, _offset_snap.y)
				if not LevelManager.platformer:
					if _static.y == 0:
						position.y = lerpf(position.y, player.position.y, 1.0)
					position_offset.y = lerpf(
							position_offset.y,
							(sign(player.gameplay_rotation_degrees) * -1.4 * 0.5 * DEFAULT_OFFSET.x * player.get_direction() * sign(player.speed_multiplier))/zoom.y + additional_offset.x,
							_offset_snap.x * framerate_compensation)
				elif abs(_player_distance.y) > (MAX_DISTANCE.x / zoom.y):
					position.y = lerpf(
							position.y,
							player.position.y - sign(_player_distance.y) * (MAX_DISTANCE.x / zoom.y),
							_position_snap.y * framerate_compensation)
				position_offset.x = lerpf(position_offset.x, DEFAULT_OFFSET.x/zoom.y + additional_offset.x, _offset_snap.y)
				if _static.x == 0 and _freefly and abs(_player_distance.x) > (MAX_DISTANCE.y / zoom.y):
					position.x = lerpf(
							position.x,
							player.position.x - sign(_player_distance.x) * (MAX_DISTANCE.y / zoom.y),
							_position_snap.y * framerate_compensation)
				elif not _freefly:
					position.x = lerpf(
							position.x,
							GroundData.center.rotated(-LevelManager.player.gameplay_rotation).y - GroundData.offset,
							_position_snap.y * framerate_compensation)
			else:
				if not LevelManager.platformer:
					if _static.x == 0:
						position.x = lerpf(position.x, player.position.x, 1.0)
					position_offset.x = lerpf(
							position_offset.x,
							(DEFAULT_OFFSET.x * player.get_direction() * sign(player.speed_multiplier))/zoom.x + additional_offset.x,
							_offset_snap.x * framerate_compensation)
				elif abs(_player_distance.x) > (MAX_DISTANCE.x / zoom.x):
					position.x = lerpf(
							position.x,
							player.position.x - sign(_player_distance.x) * (MAX_DISTANCE.x / zoom.x),
							_position_snap.x * framerate_compensation)
					position_offset.x = lerpf(
							position_offset.x,
							additional_offset.x,
							_offset_snap.x * framerate_compensation)
				position_offset.y = lerpf(position_offset.y, DEFAULT_OFFSET.y/zoom.y + additional_offset.y, _offset_snap.y)
				if _static.y == 0 and _freefly and abs(_player_distance.y) > (MAX_DISTANCE.y / zoom.y):
					position.y = lerpf(
							position.y,
							player.position.y - sign(_player_distance.y) * (MAX_DISTANCE.y / zoom.y),
							_position_snap.y * framerate_compensation)
				elif not _freefly:
					position.y = lerpf(
							position.y,
							GroundData.center.rotated(-LevelManager.player.gameplay_rotation).y - GroundData.offset,
							_position_snap.y * framerate_compensation)

		position_offset *= additional_offset_multiplier

		if _static.x == 0: position.x += position_offset.x
		if _static.y == 0: position.y += position_offset.y

		position.y = clampf(
				position.y,
				MIN_HEIGHT,
				MAX_HEIGHT)

