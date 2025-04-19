extends Node

const CELL_SIZE: int = 128

@onready var game_scene_packed := preload("res://scenes/GameScene.tscn")

var game_scene: Node2D
var current_level: String
var current_level_name: String
var is_first_attempt: bool
var level_playing: bool
var in_editor: bool
var pause_manager: Node
var player: Player
var player_duals: Array[Player]
var player_camera: PlayerCamera
var background_sprites: Array[Sprite2D]
var ground_sprites: Array[GroundObject]
var level_song_player: AudioStreamPlayer
var platformer := false
var editor_clipboard: Array[Node2D]
var editor_backup := PackedScene.new()
var editor_level_backup := PackedScene.new()
var editor_edited_level: LevelProps
var active_camera_static: CameraStaticTrigger

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	if not DirAccess.dir_exists_absolute("user://created_levels/levels"):
		DirAccess.make_dir_recursive_absolute("user://created_levels/levels")
	if not DirAccess.dir_exists_absolute("user://created_levels/songs"):
		DirAccess.make_dir_recursive_absolute("user://created_levels/songs")
