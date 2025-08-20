extends Node
class_name PulseWhite

@onready var parent := get_parent() as Interactable

var _factor: float
var _pulse_target: Node2D


func _ready() -> void:
	parent.interacted.connect(pulse)
	_pulse_target = get_node_or_null("../Sprites")
	if _pulse_target == null:
		_pulse_target = get_node_or_null("../Sprite")


func _process(delta: float) -> void:
	_factor = move_toward(_factor, 0.0, delta * 6)
	_pulse_target.material.set_shader_parameter("factor", _factor)


func pulse(_player: Player) -> void:
	if parent.has(NoEffectsComponent):
		return
	_factor = 1.0
