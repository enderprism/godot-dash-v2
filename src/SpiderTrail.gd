extends AnimatedSprite2D

class_name SpiderTrail

const SPIDER_TRAIL_HEIGHT: float = 896.0 * 0.75

@onready var trail_global_position: Vector2 # Global position
@onready var trail_rotation: float
@onready var displayed_scale_y: float = 0.0 # DISPLAYED y scale
@onready var displayed_scale_x: float = 0.0

func _ready() -> void:
	global_scale = Vector2.ONE
	scale.x = displayed_scale_y
	scale.y = displayed_scale_x
	rotation += trail_rotation
	play()
	animation_finished.connect(Callable(self, "queue_free"))

func _physics_process(_delta: float) -> void:
	global_position = trail_global_position
	scale.x = displayed_scale_y # x scale because the trail is rotated 90 degrees
	scale.y = displayed_scale_x