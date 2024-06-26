@tool
extends Node2D

## HACK Wrapped in a ParallaxLayer to make it infinite, hide when playtesting.
## TODO Wrap with a Parallax2D in 4.3

class_name EditorGrid

@export var _grid_size := Vector2i(128, 128):
	set(value):
		_grid_size = value
		queue_redraw()
@export var _primary_line_every := Vector2i(2, 2):
	set(value):
		_primary_line_every = value
		queue_redraw()
@export var _cell_size := Vector2(64, 64):
	set(value):
		_cell_size = value
		queue_redraw()
@export_flags("x", "y") var _symmetrize = 0b00:
	set(value):
		_symmetrize = value
		queue_redraw()
@export_group("Line Thickness")
@export var _primary_line_thickness: float = LINE_WIDTH_PRIMARY:
	set(value):
		_primary_line_thickness = value
		queue_redraw()
@export var _secondary_line_thickness: float = LINE_WIDTH_SECONDARY:
	set(value):
		_secondary_line_thickness = value
		queue_redraw()

const LINE_COLOR_PRIMARY := Color.WHITE
const LINE_COLOR_SECONDARY := Color("ffffff", 0.3)
const LINE_WIDTH_PRIMARY := 4.0
const LINE_WIDTH_SECONDARY := 2.0

func _draw() -> void:
	var _line_width: Vector2
	for cell_x in _grid_size.x:
		var _line_color_y: Color
		var _line_base_y = 0.0 if not _symmetrize & 0b10 else _grid_size.y * _cell_size.y
		if (cell_x % _primary_line_every.x) == 0:
			_line_color_y = LINE_COLOR_PRIMARY
			_line_width.y = _primary_line_thickness
			if not Engine.is_editor_hint():
				_line_width.y /= get_viewport().get_camera_2d().zoom.y
				_line_color_y.a *= get_viewport().get_camera_2d().zoom.y
		else:
			_line_color_y = LINE_COLOR_SECONDARY
			_line_width.y = _secondary_line_thickness
			if not Engine.is_editor_hint():
				_line_width.y /= get_viewport().get_camera_2d().zoom.y
				_line_color_y.a *= get_viewport().get_camera_2d().zoom.y
		draw_line(
			Vector2(cell_x * _cell_size.x, _line_base_y),
			Vector2(cell_x * _cell_size.x, -_grid_size.y * _cell_size.y),
			_line_color_y, _line_width.y)
		if _symmetrize & 0b01:
			draw_line(
			Vector2(-cell_x * _cell_size.x, _line_base_y),
			Vector2(-cell_x * _cell_size.x, -_grid_size.y * _cell_size.y),
			_line_color_y, _line_width.y, )
	for cell_y in _grid_size.y:
		var _line_color_x: Color
		var _line_base_x = 0.0 if not _symmetrize & 0b01 else -_grid_size.x * _cell_size.x
		if (cell_y % _primary_line_every.y) == 0:
			_line_color_x = LINE_COLOR_PRIMARY
			_line_width.x = _primary_line_thickness
			if not Engine.is_editor_hint():
				_line_width.x /= get_viewport().get_camera_2d().zoom.x
				_line_color_x.a *= get_viewport().get_camera_2d().zoom.x
		else:
			_line_color_x = LINE_COLOR_SECONDARY
			_line_width.x = _secondary_line_thickness
			if not Engine.is_editor_hint():
				_line_width.x /= get_viewport().get_camera_2d().zoom.x
				_line_color_x.a *= get_viewport().get_camera_2d().zoom.x
		draw_line(
			Vector2(_line_base_x, -cell_y * _cell_size.y),
			Vector2(_grid_size.x * _cell_size.x, -cell_y * _cell_size.y),
			_line_color_x, _line_width.x)
		if _symmetrize & 0b10:
			draw_line(
			Vector2(_line_base_x, cell_y * _cell_size.y),
			Vector2(_grid_size.x * _cell_size.x, cell_y * _cell_size.y),
			_line_color_x, _line_width.x)
