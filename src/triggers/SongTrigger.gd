@tool
extends Node2D
class_name SongTrigger

@export var song_path: String:
	set(value):
		song_path = value
		if LevelManager.level_playing:
			song_stream = LevelProps.load_song(song_path)
@export var song_start: float

var song_stream: AudioStream
var base: TriggerBase

func _ready() -> void:
	TriggerSetup.setup(self, TriggerSetup.NONE)
	base.sprite.set_texture(preload("res://assets/textures/triggers/Song.svg"))

func start(_body: Node2D) -> void:
	LevelManager.level_song_player.stream = song_stream
	LevelManager.level_song_player.play(song_start)
