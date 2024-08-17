extends Node

const CELL_SIZE: int = 128

var current_level: String
var current_level_name: String
var is_first_attempt: bool
var in_editor: bool
var pause_manager: Node
var player: Player
var player_camera: PlayerCamera
var background_sprites: Array[GDParallaxSprite]
var ground_sprites: Array[GroundObject]
var level_song_player: AudioStreamPlayer
var platformer: bool = false