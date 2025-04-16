extends Control

signal paused
signal unpaused

@onready var main_scene: PackedScene = preload("res://scenes/MainScene.tscn")

func _ready() -> void:
	$"../SettingsLayer".visible = visible
	process_mode = Node.PROCESS_MODE_ALWAYS
	LevelManager.pause_manager = self
	$VBoxContainer/LevelName.text = LevelManager.current_level_name

func _unhandled_input(event: InputEvent) -> void:
	if LevelManager.level_playing and event.is_action_pressed("restart_level"):
		_on_restart_pressed()
	if event.is_action_pressed("pause_level"):
		_on_continue_pressed()

func _on_leave_pressed() -> void:
	get_tree().paused = false
	LevelManager.platformer = false
	SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/LevelQuit.ogg")
	await get_tree().create_timer(0).timeout # Avoid the frozen frame
	get_tree().change_scene_to_packed(main_scene)

func _on_continue_pressed() -> void:
	if $"../SettingsLayer/SettingsContainer".position.y == -$"../SettingsLayer/SettingsContainer".get_viewport_rect().size.y:
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			paused.emit()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_parent().show()
			$"../SettingsLayer".show()
		else:
			unpaused.emit()
			if LevelManager.in_editor:
				# Input.mouse_mode = Input.MOUSE_MODE_CONFINED
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
			get_parent().hide()
			$"../SettingsLayer".hide()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	unpaused.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	get_parent().hide()
