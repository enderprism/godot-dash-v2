@tool
extends Node2D
class_name ReboundOrbSprite

@onready var _rebound_gradient = preload("res://resources/gradients/rebound_gradient.tres")

var factor: float:
	set(value):
		factor = value
		queue_redraw()

var _factor_smoothed: float

func _ready() -> void:
	$"../ReboundComponent".sprite = self

func _draw() -> void:
	_factor_smoothed = lerpf(_factor_smoothed, factor, 1-exp(-get_physics_process_delta_time() * 20))
	var inner_radius := lerpf(32, 52, _factor_smoothed)
	var color := _rebound_gradient.sample(_factor_smoothed)
	# Exterior ring
	draw_circle(Vector2.ZERO, 64-3, Color.WHITE, false, 6, true)
	# Interior ring
	draw_circle(Vector2.ZERO, inner_radius-3, Color.WHITE, false, 6, true)
	# Interior circle
	draw_circle(Vector2.ZERO, inner_radius-3-3, color, true, -1, true)
	# Set particle emitter color
	$"../ParticleEmitter".modulate = color