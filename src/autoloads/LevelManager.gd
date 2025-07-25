extends Node

const CELL_SIZE: int = 128

@onready var game_scene_packed := preload("res://scenes/GameScene.tscn")

var game_scene: GameScene
var current_level: LevelProps
var current_level_path: String
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
var editor_clipboard: Array[NodePath]
var editor_backup := PackedScene.new()
var editor_level_backup := PackedScene.new()
var active_camera_static: CameraStaticTrigger
var shortcut_blocker: Node

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	if not DirAccess.dir_exists_absolute("user://created_levels/levels"):
		DirAccess.make_dir_recursive_absolute("user://created_levels/levels")
	if not DirAccess.dir_exists_absolute("user://created_levels/songs"):
		DirAccess.make_dir_recursive_absolute("user://created_levels/songs")
