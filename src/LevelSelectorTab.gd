@tool extends Control

@export_file("*.tscn") var selected_level

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Button/Label".text = name
	$Button.self_modulate = self_modulate

func _process(_delta: float) -> void:
	$TabCenter.position = Vector2(size.x/2, size.y/2)

func _on_button_pressed() -> void:
	if selected_level != null and ResourceLoader.exists(selected_level, "PackedScene"):
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
		SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/LevelPlay.ogg")
		var fade_screen = get_node("/root/MainScene/FadeScreenLayer/FadeScreen")
		fade_screen.fade_in(0.5, Tween.EASE_IN_OUT, Tween.TRANS_EXPO)
		await get_tree().create_timer(0.5).timeout
		LevelManager.current_level_name = name
		LevelManager.is_first_attempt = true
		LevelManager.current_level = selected_level
		get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
