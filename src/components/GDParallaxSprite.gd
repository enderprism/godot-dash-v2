extends Sprite2D

class_name GDParallaxSprite


const NOTIFIER_WIDTH: float = 10.0
@export var _parallax_factor: Vector2
@export var _camera: PlayerCamera
# Intended for use in menus, where the GDParallaxObject needs to scroll but the camera is static.
@export var _autoscroll_speed: Vector2
@onready var _notifier_left = VisibleOnScreenNotifier2D.new()
@onready var _notifier_right = VisibleOnScreenNotifier2D.new()
var _phantomcamera_previous_position: Vector2
var _phantomcamera_delta_position: Vector2

func _ready() -> void:
	add_child(_notifier_left)
	add_child(_notifier_right)
	set_texture_repeat(TEXTURE_REPEAT_ENABLED)
	set_region_enabled(true)
	region_rect.size = Vector2(
		texture.get_size().x * 5,
		texture.get_size().y
		)
	_notifier_left.rect = Rect2(
		region_rect.position.x - region_rect.size.x/2,
		region_rect.position.y - (region_rect.size.y/2),
		NOTIFIER_WIDTH,
		region_rect.size.y,
		)
	_notifier_right.rect = Rect2(
		region_rect.position.x + region_rect.size.x/2 + NOTIFIER_WIDTH,
		region_rect.position.y - (region_rect.size.y/2),
		NOTIFIER_WIDTH,
		region_rect.size.y,
		)

func _physics_process(delta: float) -> void:
	_notifier_left.rect.position.y = to_local(get_viewport().get_camera_2d().get_screen_center_position()).y
	_notifier_right.rect.position.y = to_local(get_viewport().get_camera_2d().get_screen_center_position()).y
	if _camera != null:
		position.x += _camera._delta_position.x * _parallax_factor.x + _autoscroll_speed.x * delta
		position.y += _camera._delta_position.y * _parallax_factor.y + _autoscroll_speed.y * delta
		position.x += texture.get_width() * scale.x * (int(_notifier_right.is_on_screen()) - int(_notifier_left.is_on_screen()))
	elif get_viewport().get_camera_2d() != null:
		_phantomcamera_delta_position = get_viewport().get_camera_2d().get_screen_center_position() - _phantomcamera_previous_position
		position.x += _phantomcamera_delta_position.x * _parallax_factor.x + _autoscroll_speed.x * delta
		position.y += _phantomcamera_delta_position.y * _parallax_factor.y + _autoscroll_speed.y * delta
		position.x += texture.get_width() * scale.x * (int(_notifier_right.is_on_screen()) - int(_notifier_left.is_on_screen()))
		_phantomcamera_previous_position = get_viewport().get_camera_2d().get_screen_center_position()