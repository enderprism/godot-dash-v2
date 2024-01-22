extends Sprite2D

class_name GDParallaxSprite

@export var _parallax_factor: Vector2
@export var _camera: PlayerCamera
# Intended for use in menus, where the GDParallaxObject needs to scroll but the camera is static.
@export var _autoscroll_speed: Vector2
var _phantomcamera_previous_position: Vector2
var _phantomcamera_delta_position: Vector2
const NOTIFIER_WIDTH: float = 10.0

func _ready() -> void:
	set_texture_repeat(TEXTURE_REPEAT_ENABLED)
	set_region_enabled(true)
	region_rect.size = Vector2(
		texture.get_size().x * 5,
		texture.get_size().y
		)
	$NotifierLeft.rect = Rect2(
		region_rect.position.x - region_rect.size.x/2,
		region_rect.position.y - region_rect.size.y/2,
		NOTIFIER_WIDTH,
		region_rect.size.y,
		)
	$NotifierRight.rect = Rect2(
		region_rect.position.x + region_rect.size.x/2 + NOTIFIER_WIDTH,
		region_rect.position.y - region_rect.size.y/2,
		NOTIFIER_WIDTH,
		region_rect.size.y,
		)

func _process(delta: float) -> void:
	if _camera != null:
		position.x += _camera._delta_position.x * _parallax_factor.x + _autoscroll_speed.x * delta
		position.y += _camera._delta_position.y * _parallax_factor.y + _autoscroll_speed.y * delta
		position.x += texture.get_width() * scale.x * (int($NotifierRight.is_on_screen()) - int($NotifierLeft.is_on_screen()))
	elif get_viewport().get_camera_2d() != null:
		_phantomcamera_delta_position = get_viewport().get_camera_2d().get_screen_center_position() - _phantomcamera_previous_position
		position.x += _phantomcamera_delta_position.x * _parallax_factor.x + _autoscroll_speed.x * delta
		position.y += _phantomcamera_delta_position.y * _parallax_factor.y + _autoscroll_speed.y * delta
		position.x += texture.get_width() * scale.x * (int($NotifierRight.is_on_screen()) - int($NotifierLeft.is_on_screen()))
		_phantomcamera_previous_position = get_viewport().get_camera_2d().get_screen_center_position()
