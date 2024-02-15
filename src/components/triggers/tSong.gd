@tool
class_name tSong extends "res://src/components/triggers/tSuperclass.gd"

const EASABLE_TRIGGER = false

@export var _song_stream: AudioStream
@export var _song_start: float

func _run(_body: Node2D) -> void:
	LevelManager.level_song_player.stream = _song_stream
	LevelManager.level_song_player.play(_song_start)