extends Area2D

class_name GDTrigger

#section enums
enum TriggerType {
	MOVE,
	ROTATE,
	SCALE,
	COLOR,
	SPAWN,
}
#endsection

#section exports
@export var _trigger_type: TriggerType
#endsection

var _lerp_factor: float
var _player: Player
var _player_camera: PlayerCamera

func _ready() -> void:
	_player = LevelManager.player
	_player_camera = LevelManager.player_camera
	connect("body_entered", Callable(self, "_on_player_enter"))

func _on_player_enter() -> void:
	pass