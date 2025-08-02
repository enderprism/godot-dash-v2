@tool
extends Node2D
class_name VariableFillColor

func _process(_delta: float) -> void:
	$"../ParticleEmitter".modulate = modulate
	$"../Fill".modulate = modulate
