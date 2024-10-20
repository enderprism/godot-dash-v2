extends Node2D

var has_level_started: bool

func _ready() -> void:
	Engine.time_scale = 1
	LevelManager.in_editor = get_parent() is EditorScene
	LevelManager.background_sprites.clear()
	LevelManager.background_sprites.append($BackgroundParallax/Background)
	LevelManager.background_sprites.append($BackgroundParallax/Background2)
	LevelManager.ground_sprites.clear()
	LevelManager.level_playing = false
	LevelManager.ground_sprites.append($GroundDownParallax/GroundDownOrigin)
	LevelManager.ground_sprites.append($GroundUpParallax/GroundUpOrigin)
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)
	if not get_parent() is EditorScene:
		if LevelManager.is_first_attempt:
			$FadeScreenLayer/FadeScreen.show()
			$FadeScreenLayer/FadeScreen.modulate = Color("000000ff")
		$EditorGridParallax/EditorGrid.hide()
		var current_level = ResourceLoader.load(LevelManager.current_level, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP).instantiate()
		LevelManager.platformer = current_level.platformer
		$PlayerCamera.position_offset = PlayerCamera.DEFAULT_OFFSET if not LevelManager.platformer else Vector2.ZERO
		$Level.add_child(current_level)
		_start_level()

func _start_level() -> void:
	if LevelManager.is_first_attempt:
		await get_tree().create_timer(0.2).timeout
		$FadeScreenLayer/FadeScreen.fade_out(0.5, Tween.EASE_OUT, Tween.TRANS_EXPO)
		await $FadeScreenLayer/FadeScreen.fade_finished
		$Level.get_child(0).start_level()
		LevelManager.is_first_attempt = false
	else:
		$Level.get_child(0).start_level()

func _process(_delta: float) -> void:
	%LineUp.scale.x = 1/LevelManager.player_camera.zoom.x * 0.2
	%LineDown.scale.x = 1/LevelManager.player_camera.zoom.x * 0.2