extends Camera2D

class_name GDPlayerCamera

var previous_position: Vector2
var delta_position: Vector2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	previous_position = get_screen_center_position()
	# Camera code goes here
	delta_position = get_screen_center_position() - previous_position
