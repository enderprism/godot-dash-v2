extends Node2D
class_name PulseRing

@onready var parent := get_parent() as OrbInteractable

var _radius: float:
	set(value):
		_radius = value
		queue_redraw()
var _alpha := 1.0


func _ready() -> void:
	hide()
	parent.body_entered.connect(pulse)


func pulse(_player: Player) -> void:
	show()
	var pulse_tween := create_tween().set_parallel()
	pulse_tween.tween_property(self, ^"_radius", 128 * 1.5, 0.25)
	pulse_tween.tween_property(self, ^"_alpha", 0.0, 0.25)
	await pulse_tween.finished
	hide()
	_alpha = 1.0
	_radius = 0.0


func _draw() -> void:
	var color := Color.WHITE
	color.a = _alpha
	draw_circle(Vector2.ZERO, _radius, color, false, 2, true)