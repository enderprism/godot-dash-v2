extends Camera2D

class_name PlayerCamera

@onready var player: Player = LevelManager.player
var _previous_position: Vector2
var _delta_position: Vector2
var _horizontal_snap: float = 1.0
var _offset_snap: float = 0.5

const DEFAULT_OFFSET: Vector2 = Vector2(300.0, 0.0)

func _process(_delta: float) -> void:
	_previous_position = position

	position.x = lerpf(position.x, player.position.x, _horizontal_snap)
	if not $"../Level".get_child(0).platformer:
		offset.x = lerpf(offset.x, DEFAULT_OFFSET.x * player._get_direction(), _offset_snap)

	_delta_position = position - _previous_position
