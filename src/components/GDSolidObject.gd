extends StaticBody2D

var BASE_HITBOX_SIZE: Vector2
var BASE_HITBOX_POINT_CLOUD: PackedVector2Array

func _ready() -> void:
	if $Hitbox is CollisionShape2D and $Hitbox.shape is RectangleShape2D:
		BASE_HITBOX_SIZE = $Hitbox.shape.size
	elif $Hitbox is CollisionPolygon2D:
		BASE_HITBOX_POINT_CLOUD = $Hitbox.polygon
	$Hitbox.one_way_collision = true

func _process(delta: float) -> void:
	$Hitbox.global_rotation = LevelManager.player._gameplay_rotation
	$Hitbox.scale.y = sign(LevelManager.player._gravity_multiplier)
	if $Hitbox is CollisionShape2D and $Hitbox.shape is RectangleShape2D:
		$Hitbox.shape.size = BASE_HITBOX_SIZE.rotated(snapped(global_rotation * sign(LevelManager.player._gravity_multiplier) + LevelManager.player._gameplay_rotation, PI/2)).abs()
	elif $Hitbox is CollisionPolygon2D:
		var new_point_cloud: PackedVector2Array
		for point in BASE_HITBOX_POINT_CLOUD:
			new_point_cloud.append(point.rotated(global_rotation * sign(LevelManager.player._gravity_multiplier) + LevelManager.player._gameplay_rotation))
		$Hitbox.polygon = new_point_cloud
