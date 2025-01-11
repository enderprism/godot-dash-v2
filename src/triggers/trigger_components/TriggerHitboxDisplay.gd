extends Node2D
class_name TriggerHitboxDisplay

@onready var parent := get_parent() as TriggerBase

var shape: Rect2

func _ready() -> void:
	global_scale = Vector2.ONE

func update_shape(hitbox_shape: TriggerBase.TriggerHitboxShape, hitbox_position: Vector2, hitbox_height: float) -> void:
	global_scale = Vector2.ONE
	match hitbox_shape:
		TriggerBase.TriggerHitboxShape.LINE:
			visible = parent.sprite_visible()
			shape.size = Vector2(2.0, -hitbox_height * LevelManager.CELL_SIZE * 2)
		TriggerBase.TriggerHitboxShape.SQUARE:
			visible = parent.sprite_visible()
			shape.size = Vector2.ONE * LevelManager.CELL_SIZE * parent.global_scale
		TriggerBase.TriggerHitboxShape.DISABLED:
			hide()
	shape.position = hitbox_position - shape.size * 0.5
	queue_redraw()


func _draw() -> void:
	var hitbox_color: Color = Config.config.trigger_hitbox_color
	var hitbox_fill = hitbox_color
	hitbox_fill.a = Config.config.trigger_hitbox_fill_alpha
	draw_rect(shape, hitbox_fill, true, -1.0)
	draw_rect(shape, hitbox_color, false, 2)
