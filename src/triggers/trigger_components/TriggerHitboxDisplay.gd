extends Node2D
class_name TriggerHitboxDisplay

@onready var parent := get_parent() as TriggerBase

const EDITOR_CONFIG_PATH := "user://editor_config.ini"
var editor_config := ConfigFile.new()
var shape: Rect2

func _ready() -> void:
	editor_config.load(EDITOR_CONFIG_PATH)

func update_shape(hitbox_shape: TriggerBase.TriggerHitboxShape, hitbox_position: Vector2, hitbox_height: float) -> void:
	match hitbox_shape:
		TriggerBase.TriggerHitboxShape.LINE:
			show()
			shape.size = Vector2(2.0, -hitbox_height * LevelManager.CELL_SIZE)
		TriggerBase.TriggerHitboxShape.SQUARE:
			show()
			shape.size = Vector2.ONE * LevelManager.CELL_SIZE
		TriggerBase.TriggerHitboxShape.DISABLED:
			hide()
	shape.position = hitbox_position - shape.size * 0.5
	queue_redraw()

func _draw() -> void:
	var hitbox_color: Color = editor_config.get_value("colors", "triggers", Color.CYAN)
	var hitbox_fill = hitbox_color
	hitbox_fill.a = editor_config.get_value("colors", "hitbox_fill_alpha", 0.2)
	draw_rect(shape, hitbox_fill, true, -1.0)
	draw_rect(shape, hitbox_color, false, 2)