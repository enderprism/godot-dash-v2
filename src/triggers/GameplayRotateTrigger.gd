@tool
extends Node2D
class_name GameplayRotateTrigger


@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees" ) var _rotation_degrees: float:
	set(value):
		_rotation_degrees = value
		if _indicator != null: _indicator.queue_redraw()
@export var _reverse: bool
# @export var _set_velocity: bool:
# 	set(value):
# 		_set_velocity = value
# 		notify_property_list_changed()
# @export var _new_velocity: Vector2

# func _validate_property(property: Dictionary) -> void:
# 	if property.name == "_new_velocity" and not _set_velocity:
# 		property.usage = PROPERTY_USAGE_NO_EDITOR


var base: TriggerBase
var easing: TriggerEasing

var _players: Array[Player]
var _initial_global_rotation_degrees: Dictionary
var _indicator: GameplayRotateTriggerIndicator

func _ready() -> void:
	TriggerSetup.setup(self, false)
	_indicator = NodeUtils.get_node_or_add(self, "Indicator", load("res://src/triggers/trigger_components/GameplayRotateTriggerIndicator.gd"))
	base.sprite.set_texture(preload("res://assets/textures/triggers/GameplayRotate.svg"))
	_indicator.visible = base.sprite.visible

func start(_body: Node2D) -> void:
	# TODO edge case: 2 player instances use the trigger and get added to _players, and one of the
	# instances uses the trigger again, resulting in all instances in _player being rotated
	# this only occurs with gameplay rotations with durations bigger than 0.0, since instant
	# gameplay rotations don't rely on _players.
	var _player = _body as Player
	_player.horizontal_direction = 1 if not _reverse else -1
	_initial_global_rotation_degrees[_player] = _player.gameplay_rotation_degrees
	if _player not in _players:
		_players.append(_player)
	if is_zero_approx(easing._duration):
		if not LevelManager.platformer or _player.gravity_multiplier > 0:
			_player.gameplay_rotation_degrees = _rotation_degrees
		else:
			_player.gameplay_rotation_degrees = wrapf(_rotation_degrees + 180, -180, 180)
		if not LevelManager.platformer:
			_player.velocity = _player.velocity.rotated(deg_to_rad(_rotation_degrees))

func reset() -> void:
	if not _players.is_empty():
		for _player in _players:
			_player.gameplay_rotation_degrees = _initial_global_rotation_degrees[_player]
	elif LevelManager.in_editor and LevelManager.level_playing:
		printerr("ERR_CANT_RESET_TRIGGER: In ", name, ": this GameplayRotateTrigger holds no player references")

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(easing._weight):
		if not _players.is_empty():
			if not is_zero_approx(easing._duration):
				_indicator.show()
				var _weight_delta: float = easing._get_weight_delta()
				for _player in _players:
					var _rotation_delta: float = (_rotation_degrees - _initial_global_rotation_degrees[_player]) * _weight_delta
					_player.gameplay_rotation_degrees = lerp(_initial_global_rotation_degrees, _rotation_degrees, easing._weight)
					_player.get_node("DashFlame").rotation_degrees += _rotation_delta
					_player.get_node("DashParticles").rotation_degrees += _rotation_delta
					_player.velocity = _player.velocity.rotated(deg_to_rad(_rotation_delta))
		else:
			printerr("In ", name, ": _player is unset")
	if Engine.is_editor_hint() or LevelManager.in_editor or get_tree().is_debugging_collisions_hint():
		if _indicator.visible: _indicator.queue_redraw()
		base.sprite.global_rotation_degrees = _rotation_degrees
		base.sprite.scale = Vector2.ONE/4
		base.sprite.flip_h = _reverse
		base.sprite.flip_v = false
		if Engine.is_editor_hint(): base.position = Vector2.ZERO
