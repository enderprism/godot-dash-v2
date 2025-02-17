extends Node2D

@export var target: Node2D

@export var copy_x: bool
@export var copy_y: bool

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if target is not Camera2D:
		if copy_x:
			global_position.x = target.position.x
		if copy_y:
			global_position.y = target.position.y
	else:
		if copy_x:
			global_position.x = target.get_screen_center_position().x
		if copy_y:
			global_position.y = target.get_screen_center_position().y
