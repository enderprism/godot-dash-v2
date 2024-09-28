@tool
extends Node

@export var color := Color.WHITE

func _process(_delta: float) -> void:
	$"../ParticleEmitter".modulate = color
	$"../Fill".modulate = color