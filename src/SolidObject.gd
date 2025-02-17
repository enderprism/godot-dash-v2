@tool
extends AnimatableBody2D
class_name GDSolidObject

var BASE_HITBOXSHAPE_SIZE: Vector2
var BASE_HITBOXSHAPE_POINT_CLOUD: PackedVector2Array
var BASE_ROTATION: float

@onready var _hitbox_shape = $Hitbox

func _ready() -> void:
	if _hitbox_shape is CollisionShape2D:
		if _hitbox_shape.shape is RectangleShape2D:
			BASE_HITBOXSHAPE_SIZE = _hitbox_shape.shape.size
		elif _hitbox_shape.shape is ConvexPolygonShape2D or _hitbox_shape.shape is ConcavePolygonShape2D:
			BASE_HITBOXSHAPE_POINT_CLOUD = _hitbox_shape.shape.points
	elif _hitbox_shape is CollisionPolygon2D:
		BASE_HITBOXSHAPE_POINT_CLOUD = _hitbox_shape.polygon

func _physics_process(_delta: float) -> void:
	if has_node("Sprite"):
		$Sprite.global_scale = Vector2.ONE/4
		$Sprite.size = abs(global_scale) * 512
	if not Engine.is_editor_hint():
		_hitbox_shape.one_way_collision = not LevelManager.platformer
		_hitbox_shape.global_rotation = -abs(LevelManager.player.gameplay_rotation)
		_hitbox_shape.global_scale = Vector2.ONE

		var dash_orb_rotation: float
		if LevelManager.player.dash_control != null:
			dash_orb_rotation = LevelManager.player.dash_control.angle - LevelManager.player.gameplay_rotation
		else:
			dash_orb_rotation = -LevelManager.player.gameplay_rotation
		_hitbox_shape.global_scale.y = sign(LevelManager.player.gravity_multiplier)
		if dash_orb_rotation != 0:
			_hitbox_shape.global_scale.y *= sign(dash_orb_rotation)
		if _hitbox_shape is CollisionShape2D:
			if _hitbox_shape.shape is RectangleShape2D:
				_hitbox_shape.shape.size = _transform_rectangle_shape(sign(LevelManager.player.gravity_multiplier), LevelManager.player.gameplay_rotation)
			elif _hitbox_shape.shape is ConvexPolygonShape2D or _hitbox_shape.shape is ConcavePolygonShape2D:
				_hitbox_shape.shape.points = _transform_point_cloud(sign(LevelManager.player.gravity_multiplier), LevelManager.player.gameplay_rotation)
		elif _hitbox_shape is CollisionPolygon2D:
			_hitbox_shape.polygon = _transform_point_cloud(sign(LevelManager.player.gravity_multiplier), LevelManager.player.gameplay_rotation)

func _transform_rectangle_shape(gravity_direction: int, gameplay_rotation: float) -> Vector2:
	var transformed_size := (BASE_HITBOXSHAPE_SIZE * global_scale).rotated(global_rotation)
	return transformed_size.rotated(
		snapped(global_rotation * gravity_direction + gameplay_rotation, PI/2)).abs()

func _transform_point_cloud(gravity_direction: int, gameplay_rotation: float) -> PackedVector2Array:
	var new_point_cloud: PackedVector2Array = []
	for point in BASE_HITBOXSHAPE_POINT_CLOUD:
		var transformed_point: Vector2 = (point * global_scale)
		new_point_cloud.append(transformed_point.rotated(global_rotation * gravity_direction + gameplay_rotation))
	return new_point_cloud
