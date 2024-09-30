extends Node
class_name MusicScale

@onready var initial_scale: Vector2 = get_parent().scale


func _process(delta):
	get_parent().scale = get_parent().scale.lerp(initial_scale * (0.85 + MusicVolume.get_volume()), 1-exp(-delta * 12))