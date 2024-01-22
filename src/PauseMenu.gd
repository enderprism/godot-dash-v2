extends Control

signal paused
signal unpaused

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	LevelManager.pause_manager = self

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart_level"):
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("pause_level"):
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			emit_signal("paused")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			emit_signal("unpaused")
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN