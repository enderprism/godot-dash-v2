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
var _offset_snap: Vector2 = Vector2(0.125, 0.1)
var _freefly: bool = true

const DEFAULT_OFFSET: Vector2 = Vector2(400.0, 0.0)

var _static: Vector2i

func _ready() -> void:
	LevelManager.player_camera = self

func _process(_delta: float) -> void:
	if get_parent().has_level_started:
		_player_distance = player.position - position
		_previous_position = position

		if not $"../Level".get_child(0).platformer:
			offset.x = lerpf(offset.x, DEFAULT_OFFSET.x * player._get_direction(), _offset_snap.x)
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
