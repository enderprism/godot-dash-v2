@tool
extends Node2D
class_name tSong

@export var _song_stream: AudioStream
@export var _song_start: float

var _base: tBase
var _easing: tEasing

func _ready() -> void:
	# Avoid re-instancing tBase, tEasing and TargetLink if they already exist
	if not has_node("tBase") and not has_node("tEasing") and not has_node("TargetLink") and not has_node("BlackPad"):
		# Init children
		_base = tBase.new(); _easing = tEasing.new();
		_base.name = "tBase"
		_easing.name = "tEasing"
		# Add children to the tree
		add_child(_easing)
		add_child(_base)
		# Fix to make it show in the Scene Tree (in the Godot UI)
		_base.set_owner(get_parent()); _easing.set_owner(get_parent());
		_easing._duration = 0.0
	else:
		_base = $tBase
		_easing = $tEasing
	# Signal connections
	if not _base.is_connected("body_entered", _start): _base.body_entered.connect(_start)
	if not _base.is_connected("body_entered", _easing._start): _base.body_entered.connect(_easing._start)
	# _base._sprite.set_texture(preload("res://assets/textures/triggers/Song.svg"))

func _start(_body: Node2D) -> void:
	LevelManager.level_song_player.stream = _song_stream
	LevelManager.level_song_player.play(_song_start)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_base.position = Vector2.ZERO