extends Node

func play_sfx(sfx_path: String) -> void:
	var sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	sfx_player.stream = load(sfx_path)
	sfx_player.play()
	await sfx_player.finished
	sfx_player.queue_free()
