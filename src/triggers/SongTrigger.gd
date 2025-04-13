@tool
extends Node2D
class_name SongTrigger

@export var _song_stream: AudioStream
@export var _song_start: float

var base: TriggerBase

func _ready() -> void:
	TriggerSetup.setup(self, TriggerSetup.NONE)
	base.sprite.set_texture(preload("res://assets/textures/triggers/Song.svg"))

func start(_body: Node2D) -> void:
	LevelManager.level_song_player.stream = _song_stream
	LevelManager.level_song_player.play(_song_start)
