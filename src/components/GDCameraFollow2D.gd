extends Node2D

@export var copy_x: bool
@export var copy_y: bool

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if get_viewport().get_camera_2d() != null:
		if copy_x:
			global_position.x = get_viewport().get_camera_2d().get_screen_center_position().x
		if copy_y:
			global_position.y = get_viewport().get_camera_2d().get_screen_center_position().y