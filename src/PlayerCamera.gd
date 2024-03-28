extends Camera2D

class_name PlayerCamera

@onready var player: Player = LevelManager.player

const MIN_HEIGHT: float = -5500.0
const MAX_HEIGHT: float = 560.0
const MAX_DISTANCE: float = 200.0

var _previous_position: Vector2
var _delta_position: Vector2
var _player_distance: Vector2
var _position_snap: Vector2 = Vector2(1.0, 0.1)
var _offset_snap: Vector2 = Vector2(0.125, 0.125)
var _freefly: bool = true

const DEFAULT_OFFSET: Vector2 = Vector2(400.0, 0.0)
const DEFAULT_LIMIT_BOTTOM: int = 1080

var _static: Vector2i

func _ready() -> void:
	LevelManager.player_camera = self

func _process(_delta: float) -> void:
	limit_bottom = DEFAULT_LIMIT_BOTTOM - int(offset.y)
	if get_parent().has_level_started:
		_player_distance = player.position - position
		_previous_position = position

		# I'd love to use Vector2.rotated all over the place but it only works well with deltas, and here I change the position directly.
		# If you find out how to use a position and offset delta instead, make sure to open a PR!
		if abs(player._gameplay_rotation_degrees) == 90.0 or abs(player._gameplay_rotation_degrees) == 180.0:
			offset.x = lerpf(offset.x, DEFAULT_OFFSET.y, _offset_snap.y)
			offset.y = lerpf(offset.y, sign(player._gameplay_rotation_degrees) * 1.4 * DEFAULT_OFFSET.x * player._get_direction() * sign(player._speed_multiplier), _offset_snap.x)
			if not _static.x and _freefly and abs(_player_distance.x) > MAX_DISTANCE:
				position.x = lerpf(
					position.x,
					player.position.x - sign(_player_distance.x) * MAX_DISTANCE,
					_position_snap.x,
				)
			position.y = lerpf(position.y, player.position.y, _position_snap.y)
		else:
			offset.x = lerpf(offset.x, DEFAULT_OFFSET.x * player._get_direction() * sign(player._speed_multiplier), _offset_snap.x)
			offset.y = lerpf(offset.y, DEFAULT_OFFSET.y, _offset_snap.y)
			if not _static.y and _freefly and abs(_player_distance.y) > MAX_DISTANCE:
				position.y = lerpf(
					position.y,
					player.position.y - sign(_player_distance.y) * MAX_DISTANCE,
					_position_snap.y,
				)
			position.x = lerpf(position.x, player.position.x, _position_snap.x)
		
		position.y = clampf(
			position.y,
			MIN_HEIGHT,
			MAX_HEIGHT,
		)
		_delta_position = position - _previous_position
