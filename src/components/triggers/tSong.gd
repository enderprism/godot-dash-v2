@tool
extends Node2D
class_name tSong

@export var _song_stream: AudioStream
@export var _song_start: float

var _base: tBase

func _ready() -> void:
	TriggerSetup.setup(self, false, false)
	_base._sprite.set_texture(preload("res://assets/textures/triggers/Song.svg"))

func _start(_body: Node2D) -> void:
	LevelManager.level_song_player.stream = _song_stream
	LevelManager.level_song_player.play(_song_start)