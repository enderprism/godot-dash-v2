extends Node

const CELL_SIZE: int = 128

@onready var game_scene := preload("res://scenes/GameScene.tscn")

var current_level: String
var current_level_name: String
var is_first_attempt: bool
var level_playing: bool
var entering_editor: bool
var in_editor: bool
var pause_manager: Node
var player: Player
var player_camera: PlayerCamera
var background_sprites: Array[Sprite2D]
var ground_sprites: Array[GroundObject]
var level_song_player: AudioStreamPlayer
var platformer := false
var editor_backup := PackedScene.new()