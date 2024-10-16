extends Node2D
class_name LevelProps

@export var song: AudioStream
@export_range(0.0, 60.0, 0.01, "or_greater", "suffix:s") var song_start_time: float
@export var platformer: bool

@onready var song_player := AudioStreamPlayer.new()

var _pause_manager: Node

func _ready() -> void:
	add_child(song_player)
	_pause_manager = LevelManager.pause_manager
	LevelManager.level_song_player = song_player
	song_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	song_player.set_bus("Music")
	song_player.stream = song

func start_level() -> void:
	if get_tree().paused:
		await _pause_manager.unpaused
	song_player.play(song_start_time)
	LevelManager.level_playing = true
