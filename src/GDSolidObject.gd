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
	_hitbox_shape.one_way_collision = true

func _process(_delta: float) -> void:
	if has_node("Sprite"):
		$Sprite.global_scale = Vector2.ONE/4
		# if not Engine.is_editor_hint(): print_debug("NinePatchSprite2D: ", $Sprite.global_scale, ", self (", name ,"): ", global_scale)
		$Sprite.size = abs(scale) * 512
	if not Engine.is_editor_hint():
		# $Hitbox.global_rotation = 0.0
		# $Hitbox.global_scale = Vector2.ONE
		_hitbox_shape.global_rotation = -abs(LevelManager.player.gameplay_rotation)
		# _hitbox_shape.global_scale = Vector2.ONE
		var dash_orb_rotation = (LevelManager.player.dash_orb_rotation - LevelManager.player.gameplay_rotation)
		_hitbox_shape.scale.y = sign(LevelManager.player.gravity_multiplier) if dash_orb_rotation == 0 else sign(LevelManager.player.gravity_multiplier) * sign(dash_orb_rotation)
		if _hitbox_shape is CollisionShape2D:
			if _hitbox_shape.shape is RectangleShape2D:
				_hitbox_shape.shape.size = BASE_HITBOXSHAPE_SIZE.rotated(
					snapped(global_rotation * sign(LevelManager.player.gravity_multiplier) + LevelManager.player.gameplay_rotation, PI/2)).abs()
			elif _hitbox_shape.shape is ConvexPolygonShape2D or _hitbox_shape.shape is ConcavePolygonShape2D:
				var new_point_cloud: PackedVector2Array = []
				for point in BASE_HITBOXSHAPE_POINT_CLOUD:
					new_point_cloud.append(point.rotated(global_rotation * sign(LevelManager.player.gravity_multiplier) + LevelManager.player.gameplay_rotation))
				_hitbox_shape.shape.set_point_cloud(new_point_cloud)
		elif _hitbox_shape is CollisionPolygon2D:
			var new_point_cloud: PackedVector2Array = []
			for point in BASE_HITBOXSHAPE_POINT_CLOUD:
				new_point_cloud.append(point.rotated(global_rotation * sign(LevelManager.player.gravity_multiplier) + LevelManager.player.gameplay_rotation))
			_hitbox_shape.polygon = new_point_cloud