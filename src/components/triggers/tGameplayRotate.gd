@tool
extends Node2D
class_name tGameplayRotate


@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees" ) var _rotation_degrees: float:
	set(value):
		_rotation_degrees = value
		if _indicator != null: _indicator.queue_redraw()
@export var _flip: bool
@export var _reverse: bool
# @export var _set_velocity: bool:
# 	set(value):
# 		_set_velocity = value
# 		notify_property_list_changed()
# @export var _new_velocity: Vector2

# func _validate_property(property: Dictionary) -> void:
# 	if property.name == "_new_velocity" and not _set_velocity:
# 		property.usage = PROPERTY_USAGE_NO_EDITOR

var _player: Player # Not useful in itself, but it provides autocompletion.
var base: tBase
var easing: tEasing
var _initial_global_rotation_degrees: float
var _indicator: tGameplayRotateIndicator

func _ready() -> void:
	TriggerSetup.setup(self, false)
	_indicator = get_node_or_null("Indicator")
	if _indicator == null:
		_indicator = tGameplayRotateIndicator.new()
		_indicator.name = "Indicator"
		add_child(_indicator)
		TriggerSetup.set_child_owner(self, _indicator)
	base.sprite.set_texture(preload("res://assets/textures/triggers/GameplayRotate.svg"))
	_player = LevelManager.player
	_indicator.visible = base.sprite.visible

func _start(_body: Node2D) -> void:
	_player.gravity_multiplier = abs(_player.gravity_multiplier) * 1 if not _flip else -1
	_player.horizontal_direction = 1 if not _reverse else -1
	_initial_global_rotation_degrees = _player.gameplay_rotation_degrees
	if easing._duration == 0.0:
		_player.gameplay_rotation_degrees = _rotation_degrees
		_player.velocity = _player.velocity.rotated(deg_to_rad(_rotation_degrees))
		_indicator.hide()

func _reset() -> void:
	if _player != null:
		_player.gameplay_rotation_degrees = _initial_global_rotation_degrees
	else:
		printerr("In ", name, ": _target is unset")

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(easing._weight):
		if _player != null:
			if easing._duration > 0.0:
				var _weight_delta: float = easing._get_weight_delta()
				var _rotation_delta: float = (_rotation_degrees - _initial_global_rotation_degrees) * _weight_delta
				_player.gameplay_rotation_degrees = lerp(_initial_global_rotation_degrees, _rotation_degrees, easing._weight)
				_player.get_node("DashFlame").rotation_degrees += _rotation_delta
				_player.get_node("DashParticles").rotation_degrees += _rotation_delta
				_player.velocity = _player.velocity.rotated(deg_to_rad(_rotation_delta))
			if easing._weight == 1.0:
				_indicator.hide()
		else:
			printerr("In ", name, ": _player is unset")
	if Engine.is_editor_hint() or LevelManager.in_editor or get_tree().is_debugging_collisions_hint():
		if _indicator.visible: _indicator.queue_redraw()
		base.sprite.global_rotation_degrees = _rotation_degrees
		base.sprite.scale = Vector2.ONE/4
		base.sprite.flip_h = _reverse
		base.sprite.flip_v = _flip
		if Engine.is_editor_hint(): base.position = Vector2.ZERO