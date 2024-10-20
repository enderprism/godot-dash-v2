extends Node2D
class_name SelectionZoneDisplay


const EDITOR_CONFIG_PATH := "user://editor_config.ini"
var editor_config := ConfigFile.new()
var zone: Rect2

func _ready() -> void:
	editor_config.load(EDITOR_CONFIG_PATH)

func _draw() -> void:
	var zone_color: Color = editor_config.get_value("colors", "selection_zone", Color.GREEN)
	var zone_fill: Color = zone_color
	zone_fill.a = editor_config.get_value("colors", "selection_zone_fill_alpha", 0.2)
	draw_rect(zone, zone_fill, true, -1.0)
	draw_rect(zone, zone_color, false, 2.0)

func _on_edit_handler_selection_zone_changed(new_zone:Rect2) -> void:
	zone = new_zone
	if zone.size == Vector2.ZERO:
		hide()
	else:
		show()
		queue_redraw()