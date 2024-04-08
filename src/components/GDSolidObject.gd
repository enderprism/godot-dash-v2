@tool
extends StaticBody2D

var BASE_HITBOX_SIZE: Vector2
var BASE_HITBOX_POINT_CLOUD: PackedVector2Array

func _ready() -> void:
	if $Hitbox is CollisionShape2D:
		if $Hitbox.shape is RectangleShape2D:
			BASE_HITBOX_SIZE = $Hitbox.shape.size
		elif $Hitbox.shape is ConvexPolygonShape2D or $Hitbox.shape is ConcavePolygonShape2D:
			BASE_HITBOX_POINT_CLOUD = $Hitbox.shape.points
	elif $Hitbox is CollisionPolygon2D:
		BASE_HITBOX_POINT_CLOUD = $Hitbox.polygon
	$Hitbox.one_way_collision = true

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		$Hitbox.global_rotation = -abs(LevelManager.player._gameplay_rotation)
		var dash_orb_rotation = (LevelManager.player._dash_orb_rotation - LevelManager.player._gameplay_rotation)
		$Hitbox.scale.y = sign(LevelManager.player._gravity_multiplier) if dash_orb_rotation == 0 else sign(LevelManager.player._gravity_multiplier) * sign(dash_orb_rotation)
		if $Hitbox is CollisionShape2D:
			if $Hitbox.shape is RectangleShape2D:
				$Hitbox.shape.size = BASE_HITBOX_SIZE.rotated(
					snapped(global_rotation * sign(LevelManager.player._gravity_multiplier) + LevelManager.player._gameplay_rotation, PI/2)).abs()
			elif $Hitbox.shape is ConvexPolygonShape2D or $Hitbox.shape is ConcavePolygonShape2D:
				var new_point_cloud: PackedVector2Array
				for point in BASE_HITBOX_POINT_CLOUD:
					new_point_cloud.append(point.rotated(global_rotation * sign(LevelManager.player._gravity_multiplier) + LevelManager.player._gameplay_rotation))
				$Hitbox.shape.set_point_cloud(new_point_cloud)
		elif $Hitbox is CollisionPolygon2D:
			var new_point_cloud: PackedVector2Array
			for point in BASE_HITBOX_POINT_CLOUD:
				new_point_cloud.append(point.rotated(global_rotation * sign(LevelManager.player._gravity_multiplier) + LevelManager.player._gameplay_rotation))
			$Hitbox.polygon = new_point_cloud
	
	if has_node("NinePatchRect"):
		$NinePatchRect.scale = Vector2(0.25, 0.25) / scale.abs()
		$NinePatchRect.size = Vector2(512.0, 512.0) * scale.abs()
		$NinePatchRect.position = -$NinePatchRect.size/2
		$NinePatchRect.pivot_offset = $NinePatchRect.size/2
