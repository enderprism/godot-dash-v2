extends Node2D

var _global_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_global_position = global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	global_position = _global_position


func _on_animation_finished() -> void:
	queue_free()
