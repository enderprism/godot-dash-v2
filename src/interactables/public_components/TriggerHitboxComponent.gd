extends Component
class_name TriggerHitboxComponent

enum HitboxShape {
	LINE,
	SQUARE,
	DISABLED
}

@export var _hitbox: CollisionShape2D
@export var hitbox_shape: HitboxShape:
	set(value):
		hitbox_shape = value
		if _hitbox == null:
			return
		print_debug(value)
		match value:
			HitboxShape.LINE:
				_hitbox.shape = SegmentShape2D.new()
				_hitbox.shape.a = Vector2(0, -hitbox_height * LevelManager.CELL_SIZE)
				_hitbox.shape.b = Vector2(0,  hitbox_height * LevelManager.CELL_SIZE)
			HitboxShape.SQUARE:
				_hitbox.shape = RectangleShape2D.new()
				_hitbox.shape.size = Vector2.ONE * LevelManager.CELL_SIZE
			HitboxShape.DISABLED:
				_hitbox.shape = null

@export var hitbox_height: float = 64.0:
	set(value):
		hitbox_height = value
		if hitbox_shape != HitboxShape.LINE or _hitbox == null:
			return
		_hitbox.shape = SegmentShape2D.new()
		_hitbox.shape.a = Vector2(0, -value * LevelManager.CELL_SIZE)
		_hitbox.shape.b = Vector2(0,  value * LevelManager.CELL_SIZE)
