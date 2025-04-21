extends Node2D

var has_level_started: bool

func _ready() -> void:
	LevelManager.game_scene = self
	Engine.time_scale = 1
	LevelManager.active_camera_static = null
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
		LevelManager.player.process_mode = Node.PROCESS_MODE_DISABLED
		$PauseMenuLayer/PauseMenu.leave.connect(_leave_level)
		if LevelManager.is_first_attempt:
			$FadeScreenLayer/FadeScreen.show()
			$FadeScreenLayer/FadeScreen.modulate = Color("000000ff")
		$EditorGridParallax/EditorGrid.hide()
		ResourceLoader.load_threaded_request(LevelManager.current_level, "PackedScene", false, ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		var current_level: Node = ResourceLoader.load_threaded_get(LevelManager.current_level).instantiate()
		LevelManager.platformer = current_level.platformer
		$Level.add_child(current_level)
		SceneTransition.previous = SceneTransition.Scene.LEVEL
		_start_level()

func _start_level() -> void:
	if LevelManager.is_first_attempt:
		await get_tree().create_timer(0.2).timeout
		$FadeScreenLayer/FadeScreen.fade_out(0.5, Tween.EASE_OUT, Tween.TRANS_SINE)
		await $FadeScreenLayer/FadeScreen.fade_finished
		$Level.get_child(0).start_level()
		LevelManager.is_first_attempt = false
	else:
		$Level.get_child(0).start_level()
	LevelManager.player.process_mode = Node.PROCESS_MODE_INHERIT


func _leave_level() -> void:
	if $Level.get_child(0) != null:
		$Level.get_child(0).stop_level()
	LevelManager.player.process_mode = Node.PROCESS_MODE_DISABLED
	LevelManager.player_camera.process_mode = Node.PROCESS_MODE_DISABLED
	$FadeScreenLayer/FadeScreen.fade_in(0.5, Tween.EASE_IN, Tween.TRANS_SINE)



func _process(_delta: float) -> void:
	for ground_sprite in LevelManager.ground_sprites:
		ground_sprite.get_node("Ground/Line").scale.x = 1/LevelManager.player_camera.zoom.x * 0.2
