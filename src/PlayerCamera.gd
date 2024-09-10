extends Camera2D

class_name PlayerCamera

@onready var player: Player = LevelManager.player

const DEFAULT_ZOOM: Vector2 = Vector2(0.8, 0.8)
const MIN_HEIGHT: float = -5500.0
const MAX_HEIGHT: float = 413.0
const MAX_DISTANCE: float = 200.0

var _previous_position: Vector2
var _delta_position: Vector2
var _player_distance: Vector2
var _position_snap: Vector2 = Vector2(1.0, 0.1)
var _offset_snap: Vector2 = Vector2(0.125, 0.125)
var _freefly: bool = true
# I use a fake offset (which modifies the position) instead of a real one because
# it makes the camera static transition weird
var _position_offset: Vector2

const DEFAULT_OFFSET: Vector2 = Vector2(400.0, 0.0)
const DEFAULT_LIMIT_BOTTOM: int = 1080

var _static: Vector2i
var _tOffset: Vector2
var _tOffset_multiplier: Vector2 = Vector2.ONE

func _ready() -> void:
	position += DEFAULT_OFFSET
	_position_offset = DEFAULT_OFFSET
	LevelManager.player_camera = self

func _physics_process(_delta: float) -> void:
	# limit_bottom = DEFAULT_LIMIT_BOTTOM - int(offset.y)
	if get_parent().has_level_started:
		_player_distance = player.position - position
		_delta_position = get_screen_center_position() - _previous_position
		_previous_position = get_screen_center_position()

		# TODO make the camera movement rotation-independant
		# I'd love to use Vector2.rotated all over the place but it only works well with deltas, and here I change the position directly.
		# If you find out how to use a position and offset delta instead, make sure to open a PR!
		if abs(player.gameplay_rotation_degrees) == 90.0 or abs(player.gameplay_rotation_degrees) == 180.0:
			_position_offset.x = lerpf(_position_offset.x, DEFAULT_OFFSET.y/zoom.x, _offset_snap.y)
			if not LevelManager.platformer:
				_position_offset.y = lerpf(
					_position_offset.y,
					(sign(player.gameplay_rotation_degrees) * -1.4 * 0.5 * DEFAULT_OFFSET.x * player._get_direction() * sign(player.speed_multiplier))/zoom.y, _offset_snap.x
				)
			else:
				_position_offset.y = lerpf(
					_position_offset.y,
					(sign(player.gameplay_rotation_degrees) * -DEFAULT_OFFSET.x * player._get_direction() * sign(player.speed_multiplier))/zoom.y, _offset_snap.x * 0.5
				)
			if _static.x == 0 and _freefly and abs(_player_distance.x) > ((MAX_DISTANCE+200) / zoom.y):
				position.x = lerpf(
					position.x,
					player.position.x - sign(_player_distance.x) * ((MAX_DISTANCE+200) / zoom.y),
					_position_snap.y,
				)
			elif not _freefly:
				position.x = lerpf(
					position.x,
					GroundData.center.rotated(-LevelManager.player.gameplay_rotation).y - GroundData.offset,
					_position_snap.y
				)
			if _static.y == 0: position.y = lerpf(position.y, player.position.y, _position_snap.x)
		else:
			if not LevelManager.platformer:
				_position_offset.x = lerpf(
					_position_offset.x,
					(DEFAULT_OFFSET.x * player._get_direction() * sign(player.speed_multiplier))/zoom.x, _offset_snap.x
				)
			else:
				_position_offset.x = lerpf(
					_position_offset.x,
					(-DEFAULT_OFFSET.x * 0.5 * player._get_direction() * sign(player.speed_multiplier))/zoom.x, _offset_snap.x * 0.5
				)
			_position_offset.y = lerpf(_position_offset.y, DEFAULT_OFFSET.y/zoom.y, _offset_snap.y)
			if _static.y == 0 and _freefly and abs(_player_distance.y) > (MAX_DISTANCE / zoom.y):
				position.y = lerpf(
					position.y,
					player.position.y - sign(_player_distance.y) * (MAX_DISTANCE / zoom.y),
					_position_snap.y,
				)
			elif not _freefly:
				position.y = lerpf(
					position.y,
					GroundData.center.rotated(-LevelManager.player.gameplay_rotation).y - GroundData.offset,
					_position_snap.y
				)
			if _static.x == 0: position.x = lerpf(position.x, player.position.x, _position_snap.x)

		_position_offset *= _tOffset_multiplier
		_position_offset += _tOffset

		if _static.x == 0: position.x += _position_offset.x
		if _static.y == 0: position.y += _position_offset.y

		position.y = clampf(
			position.y,
			MIN_HEIGHT,
			MAX_HEIGHT,
		)

