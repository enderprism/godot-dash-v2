@tool
extends Node2D
class_name ReboundPadSprite

@onready var _rebound_gradient = preload("res://resources/gradients/rebound_gradient.tres")

var factor: float:
	set(value):
		factor = value
		queue_redraw()

var _factor_smoothed: float

func _ready() -> void:
	$"../../ReboundComponent".sprite = self

func _draw() -> void:
	_factor_smoothed = lerpf(_factor_smoothed, factor, 1-exp(-get_physics_process_delta_time() * 20))
	var inner_radius := lerpf(62*1.2, 62*0.9, _factor_smoothed)
	var color := _rebound_gradient.sample(_factor_smoothed)
	var draw_height := lerpf(60, 30, factor)
	var draw_position := Vector2(0, draw_height)
	# Exterior arc
	draw_circle(draw_position, inner_radius, Color.WHITE, false, 4)
	# Interior arc
	draw_circle(draw_position, inner_radius-2, color, true)
	# Set particle emitter color
	$"../../ParticleEmitter".modulate = color
