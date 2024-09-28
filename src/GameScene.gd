extends Node2D

var has_level_started: bool

func _ready() -> void:
	LevelManager.in_editor = get_parent() is EditorScene
	LevelManager.background_sprites.clear()
	LevelManager.background_sprites.append($BackgroundParallax/Background)
	LevelManager.background_sprites.append($BackgroundParallax/Background2)
	LevelManager.ground_sprites.clear()
	LevelManager.ground_sprites.append($GroundDownParallax/GroundDownOrigin)
	LevelManager.ground_sprites.append($GroundUpParallax/GroundUpOrigin)
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)
	if not get_parent() is EditorScene:
		$EditorGridParallax/EditorGrid.hide()
		var current_level = ResourceLoader.load(LevelManager.current_level, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE).instantiate()
		LevelManager.platformer = current_level.platformer
		$PlayerCamera.position_offset = PlayerCamera.DEFAULT_OFFSET if not LevelManager.platformer else Vector2.ZERO
		$Level.add_child(current_level)
		_start_level()

func _start_level() -> void:
	if LevelManager.is_first_attempt:
		$FadeScreenLayer/FadeScreen.fade_out(0.2, Tween.EASE_OUT, Tween.TRANS_SINE)
		await $FadeScreenLayer/FadeScreen.fade_finished
		await get_tree().create_timer(0.2).timeout
		$Level.get_child(0).start_level()
		has_level_started = true
		LevelManager.is_first_attempt = false
	else:
		await get_tree().create_timer(get_physics_process_delta_time()).timeout
		$Level.get_child(0).start_level()
		has_level_started = true

func _process(_delta: float) -> void:
	%LineUp.scale.x = 1/LevelManager.player_camera.zoom.x * 0.2
	%LineDown.scale.x = 1/LevelManager.player_camera.zoom.x * 0.2