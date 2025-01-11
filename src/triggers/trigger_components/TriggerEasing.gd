@tool class_name TriggerEasing extends Node
## Interpolates a given property of a target to a value using a
## trigger easing resource.

var _tween: Tween
var _weight: float

signal finished

# Tween controls
@export_range(0.0, 10.0, 0.0001, "or_more") var _duration: float = 1.0
@export var easing_type: Tween.EaseType = Tween.EASE_IN_OUT
@export var easing_transition: Tween.TransitionType

var _previous_weight: float

func _ready() -> void:
	if has_node("../TriggerBase"):
		$"../TriggerBase".body_entered.connect(start)

func start(_body: Node2D) -> void:
	_tween = get_tree().create_tween()
	if not $"../TriggerBase".single_usage:
		reset()
		_tween.tween_property(self, "_weight", 1.0, _duration) \
			.set_trans(easing_transition) \
			.set_ease(easing_type).from(0.0)
	else:
		_tween.tween_property(self, "_weight", 1.0, _duration) \
			.set_trans(easing_transition) \
			.set_ease(easing_type)
	_tween.finished.connect(func(): finished.emit())

func _get_weight_delta() -> float:
	var _result = _weight - _previous_weight
	_previous_weight = _weight
	return _result

func _is_inactive() -> bool:
	return _weight == 0.0 or _weight == 1.0

func reset() -> void:
	_weight = 0.0
	_previous_weight = 0.0
