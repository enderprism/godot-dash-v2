extends Node2D
class_name LevelProps

const START_SPEED: Array[float] = [
	0.0,   # 0x
	0.807, # 0.5x
	1.0,   # 1x
	1.243, # 2x
	1.502, # 3x
	1.849, # 4x
	2.431, # 5x
]

@export_file var song_path: String:
	set(value):
		song_path = value
		update_song(value)
@export_range(0.0, 60.0, 0.01, "or_greater", "suffix:s") var song_start_time: float
@export var platformer: bool
@export var start_speed: int = 2
@export var start_reverse: bool
@export var start_gameplay_rotation_degrees: float

@onready var song_player := AudioStreamPlayer.new()

@export var color_channels: Array[ColorChannelData]
var _pause_manager: Node

func _ready() -> void:
	_pause_manager = LevelManager.pause_manager
	update_song(song_path)
	song_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	song_player.set_bus("Music")
	LevelManager.level_song_player = song_player
	add_child(song_player)
	setup_color_channel_watchers()


func start_level() -> void:
	if get_tree().paused:
		await _pause_manager.unpaused
	song_player.play(song_start_time)
	LevelManager.platformer = platformer
	LevelManager.player.speed_multiplier = START_SPEED[start_speed]
	LevelManager.player.horizontal_direction = -1 if start_reverse else 1
	LevelManager.player.gameplay_rotation_degrees = start_gameplay_rotation_degrees
	LevelManager.player_camera.position_offset = PlayerCamera.DEFAULT_OFFSET.rotated(start_gameplay_rotation_degrees) if not LevelManager.platformer else Vector2.ZERO
	LevelManager.player_camera.position = LevelManager.player.position
	LevelManager.level_playing = true


func stop_level() -> void:
	song_player.stop()
	LevelManager.player_duals.clear()
	LevelManager.level_playing = false
	process_mode = Node.PROCESS_MODE_DISABLED


func setup_color_channel_watchers() -> void:
	for color_channel in color_channels:
		var watcher := ColorChannelWatcher.new(color_channel)
		add_child(watcher)


func update_song(path: String) -> void:
	if path.is_empty() or song_player == null:
		return
	var audio_stream: AudioStream
	match song_path.get_extension():
		"mp3":
			audio_stream = AudioStreamMP3.load_from_file(path)
		"wav":
			audio_stream = AudioStreamWAV.load_from_file(path)
		"ogg":
			audio_stream = AudioStreamOggVorbis.load_from_file(path)
		_:
			printerr("Song isn't of valid type")
	song_player.stream = audio_stream
