@tool
extends Node2D
class_name tGameplayRotateIndicator

const HELPER_ARC_WIDTH: float = 8.0

func _ready() -> void:
	show_behind_parent = true

func _process(_delta: float) -> void:
	global_rotation = 0.0

func _draw() -> void:
	draw_arc(
		Vector2.ZERO, # origin (local coordinates)
		64 - (HELPER_ARC_WIDTH/2), # radius
		-get_parent().global_rotation, # angle A
		deg_to_rad(get_parent()._rotation_degrees - get_parent().global_rotation_degrees), # angle B
		50, # point count
		Color.ORANGE, # color
		HELPER_ARC_WIDTH, # line width
		false) # antialiasing