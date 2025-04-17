extends Node2D
class_name LevelProps

@export var song: AudioStream
@export_range(0.0, 60.0, 0.01, "or_greater", "suffix:s") var song_start_time: float
@export var platformer: bool

@onready var song_player := AudioStreamPlayer.new()

@export var color_channels: Array[ColorChannelData]
var _pause_manager: Node

func _ready() -> void:
	add_child(song_player)
	_pause_manager = LevelManager.pause_manager
	LevelManager.level_song_player = song_player
	song_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	song_player.set_bus("Music")
	song_player.stream = song
	setup_color_channel_watchers()


func start_level() -> void:
	if get_tree().paused:
		await _pause_manager.unpaused
	song_player.play(song_start_time)
	LevelManager.level_playing = true


func stop_level() -> void:
	song_player.stop()
	LevelManager.level_playing = false


func setup_color_channel_watchers() -> void:
	for color_channel in color_channels:
		var watcher := ColorChannelWatcher.new(color_channel)
		add_child(watcher)
