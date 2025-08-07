extends Node2D
class_name PulseCircle

@export var no_blending := false
@onready var parent := get_parent() as Interactable

const RADIUS := 128 * 1.25


var _radius: float = RADIUS:
	set(value):
		_radius = value
		queue_redraw()


func _ready() -> void:
	if parent is OrbInteractable:
		parent.pressed.connect(pulse)
	else:
		parent.body_entered.connect(pulse)
	hide()
	modulate.a = 0.5
	if not no_blending:
		material = preload("res://resources/AdditiveBlendingMaterial.tres")


func pulse(_player: Player) -> void:
	if parent.no_effects:
		return
	show()
	var pulse_tween := create_tween().set_parallel()
	pulse_tween.tween_property(self, ^"_radius", 0.0, 0.25)
	await pulse_tween.finished
	hide()
	_radius = RADIUS


func _draw() -> void:
	var color: Color = $"../ParticleEmitter".modulate
	draw_circle(Vector2.ZERO, _radius, color, true, -1, true)
