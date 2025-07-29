@tool
extends Node2D
class_name SongTrigger

@export var song_path: String:
	set(value):
		if LevelManager.current_level != null:
			LevelManager.current_level.register_required_song(song_path, value)
		song_path = value
		ResourceLoader.load_threaded_request(value)
@export var song_start: float

var base: TriggerBase

func _ready() -> void:
	ResourceLoader.load_threaded_request(song_path)
	LevelManager.current_level.register_required_song(song_path, song_path)
	TriggerSetup.setup(self, TriggerSetup.NONE)
	base.sprite.set_texture(preload("res://assets/textures/triggers/Song.svg"))

func start(_body: Node2D) -> void:
	LevelManager.level_song_player.stream = ResourceLoader.load_threaded_get(song_path)
	LevelManager.level_song_player.play(song_start)
	print(LevelManager.level_song_player.stream)
