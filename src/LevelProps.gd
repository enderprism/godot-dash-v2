extends Node2D

@export var song: AudioStream
@export_range(0.0, 60.0, 0.01, "or_greater", "suffix:s") var song_start_time: float
@export var platformer: bool

func start_level() -> void:
	var song_player = AudioStreamPlayer.new()
	add_child(song_player)
	song_player.stream = song
	song_player.play(song_start_time)