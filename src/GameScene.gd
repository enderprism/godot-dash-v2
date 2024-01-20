extends Node2D

var has_level_started: bool

func _ready() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)
	var current_level = LevelManager.current_level.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	$Level.add_child(current_level)
	if LevelManager.is_first_attempt:
		$FadeScreenLayer/FadeScreen.fade_out(0.2, Tween.EASE_OUT, Tween.TRANS_SINE)
		await $FadeScreenLayer/FadeScreen.fade_finished
		has_level_started = true
		$Level.get_child(0).start_level()