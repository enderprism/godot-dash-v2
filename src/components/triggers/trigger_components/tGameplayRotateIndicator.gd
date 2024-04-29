@tool
extends Node2D
class_name tGameplayRotateIndicator

const THICKNESS: float = 8.0
const POINT_COUNT: int = 50
const ANTIALIASED: bool = false

var _origin: Vector2 = Vector2.ZERO
var _radius: float
var _angle_A: float
var _angle_B: float
var _color: Color

func _ready() -> void:
	show_behind_parent = true

func _process(_delta: float) -> void:
	global_rotation = 0.0

func _draw() -> void:
	# TODO: make the indicator's angle relative to the player's gameplay rotation in-game
	if get_parent()._base._sprite.visible:
		_angle_A = 0.0
		if not Engine.is_editor_hint():
			_angle_A += LevelManager.player._gameplay_rotation
		_angle_B = deg_to_rad(get_parent()._rotation_degrees)
		_color = Color.CYAN if sign(_angle_B - _angle_A) == 1 else Color.MAGENTA
		_radius = 64 - (THICKNESS/2)
		draw_arc(
			_origin, # origin (local coordinates)
			_radius, # radius
			_angle_A,
			_angle_B, # angle B
			POINT_COUNT,
			_color, # color
			THICKNESS, # line width
			ANTIALIASED) # antialiasing