extends Node2D

var has_level_started: bool

func _ready() -> void:
	LevelManager.in_editor = get_parent() is EditorScene
	LevelManager.background_sprites.append($Background)
	LevelManager.background_sprites.append($Background2)
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)
	if not get_parent() is EditorScene:
		$EditorGrid.hide()
		var current_level = ResourceLoader.load(LevelManager.current_level, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE).instantiate()
		$Level.add_child(current_level)
		_start_level()

func _start_level() -> void:
	if LevelManager.is_first_attempt:
		$FadeScreenLayer/FadeScreen.fade_out(0.2, Tween.EASE_OUT, Tween.TRANS_SINE)
		await $FadeScreenLayer/FadeScreen.fade_finished
		await get_tree().create_timer(0.2).timeout
		has_level_started = true
		$Level.get_child(0).start_level()
		LevelManager.is_first_attempt = false
	else:
		await get_tree().create_timer(get_physics_process_delta_time()).timeout
		has_level_started = true
		$Level.get_child(0).start_level()
