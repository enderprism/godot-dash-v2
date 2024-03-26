@tool class_name tEasing extends Node
## Interpolates a given property of a target to a value using a
## trigger easing resource.

var _tween: Tween
var _weight: float

# Tween controls
@export_range(0.0, 10.0, 0.01, "or_more") var _duration: float
@export var _easing_type: Tween.EaseType
@export var _easing_transition: Tween.TransitionType

var _previous_weight: float

func _ready() -> void:
	if has_node("../tBase"):
		$"../tBase".body_entered.connect(_start)

func _start(_body: Node2D) -> void:
	_tween = get_tree().create_tween()
	_tween.tween_property(self, "_weight", 1.0, _duration) \
		.set_trans(_easing_transition) \
		.set_ease(_easing_type)

func _get_weight_delta() -> float:
	var _result = _weight - _previous_weight
	_previous_weight = _weight
	return _result
