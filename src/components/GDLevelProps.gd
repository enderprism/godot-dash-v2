extends Node2D

@export var song: AudioStream
@export_range(0.0, 60.0, 0.01, "or_greater", "suffix:s") var song_start_time: float
@export var platformer: bool

var _pause_manager

func start_level() -> void:
	_pause_manager = LevelManager.pause_manager
	var song_player = AudioStreamPlayer.new()
	add_child(song_player)
	song_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	song_player.stream = song
	if get_tree().paused:
		await _pause_manager.unpaused
		song_player.play(song_start_time)
	else:
		song_player.play(song_start_time)
