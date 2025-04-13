@tool
extends Node2D
class_name EditorGrid

@export var grid_size := Vector2i.ONE * LevelManager.CELL_SIZE:
	set(value):
		grid_size = value
		queue_redraw()
@export var primary_line_every := Vector2i(2, 2):
	set(value):
		primary_line_every = value
		queue_redraw()
@export var cell_size := Vector2.ONE * LevelManager.CELL_SIZE:
	set(value):
		cell_size = value
		queue_redraw()
@export_flags("x", "y") var symmetrize = int(Axis.NONE):
	set(value):
		symmetrize = value
		queue_redraw()
@export_flags("x", "y") var odd = int(Axis.NONE):
	set(value):
		odd = value
		queue_redraw()
@export_group("Line Thickness")
@export var primary_line_thickness: float = LINE_WIDTH_PRIMARY:
	set(value):
		primary_line_thickness = value
		queue_redraw()
@export var secondary_line_thickness: float = LINE_WIDTH_SECONDARY:
	set(value):
		secondary_line_thickness = value
		queue_redraw()

const LINE_COLOR_PRIMARY := Color.WHITE
const LINE_COLOR_SECONDARY := Color("ffffff", 0.3)
const LINE_WIDTH_PRIMARY := 4.0
const LINE_WIDTH_SECONDARY := 2.0

enum Axis {
	NONE = 0,
	X = 1 << 0,
	Y = 1 << 1,
}


func _ready() -> void:
	if get_parent() is Parallax2D:
		get_parent().repeat_size = Vector2(grid_size) * cell_size * 2
	visible = LevelManager.in_editor


func _draw() -> void:
	var line_width: Vector2
	for cell_x in grid_size.x + 1:
		var line_color_y: Color
		var _line_base_y = 0.0 if not symmetrize & Axis.Y else grid_size.y * cell_size.y
		if (cell_x % primary_line_every.x) == 0:
			line_color_y = LINE_COLOR_PRIMARY
			line_width.y = primary_line_thickness
		else:
			line_color_y = LINE_COLOR_SECONDARY
			line_width.y = secondary_line_thickness
			if not Engine.is_editor_hint():
				line_width.y /= get_viewport().get_camera_2d().zoom.y
				line_color_y.a *= get_viewport().get_camera_2d().zoom.y
		var cell_offset := 0.0
		if odd & Axis.X:
			cell_offset = cell_size.x / 2
		draw_line(
			Vector2(cell_x * cell_size.x + cell_offset, _line_base_y),
			Vector2(cell_x * cell_size.x + cell_offset, -grid_size.y * cell_size.y),
			line_color_y, line_width.y)
		if symmetrize & Axis.Y:
			draw_line(
				Vector2(-cell_x * cell_size.x + cell_offset, _line_base_y),
				Vector2(-cell_x * cell_size.x + cell_offset, -grid_size.y * cell_size.y),
				line_color_y, line_width.y)
	for cell_y in grid_size.y + 1:
		var line_color_x: Color
		var line_base_x = 0.0 if not symmetrize & Axis.X else -grid_size.x * cell_size.x
		if (cell_y % primary_line_every.y) == 0:
			line_color_x = LINE_COLOR_PRIMARY
			line_width.x = primary_line_thickness
		else:
			line_color_x = LINE_COLOR_SECONDARY
			line_width.x = secondary_line_thickness
		var cell_offset := 0.0
		if odd & Axis.Y:
			cell_offset = cell_size.y / 2
		draw_line(
			Vector2(line_base_x, -cell_y * cell_size.y + cell_offset),
			Vector2(grid_size.x * cell_size.x, -cell_y * cell_size.y + cell_offset),
			line_color_x, line_width.x)
		if symmetrize & Axis.Y:
			draw_line(
				Vector2(line_base_x, cell_y * cell_size.y + cell_offset),
				Vector2(grid_size.x * cell_size.x, cell_y * cell_size.y + cell_offset),
				line_color_x, line_width.x)
