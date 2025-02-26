@tool
extends Node2D
class_name ReboundOrbSprite

@onready var _rebound_gradient = preload("res://resources/gradients/rebound_gradient.tres")

var factor: float

var _factor_smoothed: float

func _ready() -> void:
	if has_node("../ReboundComponent"):
		$"../ReboundComponent".sprite = self

func _process(_delta: float) -> void:
	global_scale = Vector2.ONE
	queue_redraw()

func _draw() -> void:
	_factor_smoothed = lerpf(_factor_smoothed, factor, 1-exp(-get_physics_process_delta_time() * 20))
	var inner_radius := lerpf(32, 52, _factor_smoothed)
	var color := _rebound_gradient.sample(_factor_smoothed)
	var scale_avg: float = 1.0
	if get_parent() is Area2D:
		scale_avg = 0.5 * (get_parent().global_scale.x + get_parent().global_scale.y)
	# Exterior ring
	draw_circle(Vector2.ZERO, (64-3) * scale_avg, Color.WHITE, false, 6 * scale_avg, true)
	# Interior ring
	draw_circle(Vector2.ZERO, (inner_radius-3) * scale_avg, Color.WHITE, false, 6 * scale_avg, true)
	# Interior circle
	draw_circle(Vector2.ZERO, (inner_radius-3-3) * scale_avg, color, true, -1, true)
	# Set particle emitter color
	if has_node("../ParticleEmitter"):
		$"../ParticleEmitter".modulate = color
