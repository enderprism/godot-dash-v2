@tool class_name TriggerEasing extends Node
## Interpolates a given property of a target to a value using a
## trigger easing resource.

signal finished

# Tween controls
@export_range(0.0, 10.0, 0.0001, "or_more") var duration: float = 1.0
@export var keep_active: bool ## Keep the easing active after it completes.
@export var easing_type: Tween.EaseType = Tween.EASE_IN_OUT
@export var easing_transition: Tween.TransitionType

var weight_delta: float
var tween: Tween
var weight: float
var _previous_weight: float

func _ready() -> void:
	if has_node("../TriggerBase"):
		$"../TriggerBase".body_entered.connect(start)

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		weight_delta = get_weight_delta()

func start(_body: Node2D) -> void:
	tween = get_tree().create_tween()
	if not $"../TriggerBase".single_usage:
		reset()
		tween.tween_property(self, "weight", 1.0, duration) \
			.set_trans(easing_transition) \
			.set_ease(easing_type).from(0.0)
	else:
		tween.tween_property(self, "weight", 1.0, duration) \
			.set_trans(easing_transition) \
			.set_ease(easing_type)
	tween.finished.connect(func(): finished.emit())

func get_weight_delta() -> float:
	var result = weight - _previous_weight
	_previous_weight = weight
	return result

func is_inactive() -> bool:
	return weight == 0.0 or (_previous_weight == 1.0 and not keep_active)

func reset() -> void:
	weight = 0.0
	_previous_weight = 0.0
