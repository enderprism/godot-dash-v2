extends AnimatedSprite2D

class_name GDSpiderTrail

const SPIDER_TRAIL_HEIGHT: float = 896.0 * 0.75

@onready var _global_position: Vector2 # Global position
@onready var _rotation: float
@onready var _scale_y: float = 0.0 # DISPLAYED y scale
@onready var _scale_x: float = 0.0

func _ready() -> void:
	global_scale = Vector2.ONE
	scale.x = _scale_y
	scale.y = _scale_x
	rotation += _rotation
	play()
	animation_finished.connect(Callable(self, "queue_free"))

func _physics_process(_delta: float) -> void:
	global_position = _global_position
	scale.x = _scale_y # x scale because the trail is rotated 90 degrees
	scale.y = _scale_x