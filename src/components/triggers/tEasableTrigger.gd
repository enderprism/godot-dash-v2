@tool
extends "res://src/components/triggers/tSuperclass.gd"

const EASABLE_TRIGGER = true

@export var _target_group: Node2D
@export var _relative: bool
@export var _tween_properties: GDTriggerEasing

@onready var _lerp_tween: Tween
var _lerp_weight: float
var _custom_curve_lerp_weight: float ## Intermediary weight for [member GDTriggerEasing._custom_easing].
var _initial_value
var _initial_value_set: bool


func _start_lerp_tween() -> void:
	_lerp_tween = get_tree().create_tween()
	if _tween_properties != null:
		if not _tween_properties._use_custom_easing:
			_lerp_tween.tween_property(self, "_lerp_weight", 1.0, _tween_properties._tween_duration) \
				.set_ease(_tween_properties._tween_easing) \
				.set_trans(_tween_properties._tween_transition) \
				.from(0.0)
		elif _tween_properties._custom_easing != null:
			_lerp_tween.tween_property(self, "_custom_curve_lerp_weight", 1.0, _tween_properties._tween_duration).from(0.0)

func _get_lerp_weight() -> float:
	if _tween_properties != null:
		if not _tween_properties._use_custom_easing:
			return _lerp_weight
		elif _tween_properties._custom_easing != null:
			return _tween_properties._custom_easing.sample(_custom_curve_lerp_weight)
	return 0.0

func _cancel() -> void:
	if _lerp_tween != null:
		_lerp_tween.kill()
	_lerp_weight = 0.0
	_custom_curve_lerp_weight = 0.0