extends Node2D
class_name HitboxDisplay

@export var hitbox: CollisionShape2D
@export var color: Color


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	match hitbox.shape:
		var rectangle when hitbox.shape is RectangleShape2D:
			draw_rect(Rect2(-rectangle.size / 2, rectangle.size), color, false, 4.0)
		var line when hitbox.shape is SegmentShape2D:
			draw_line(line.a, line.b, color, 4.0)

