extends Node
class_name RotatedSpeed

@onready var parent := get_parent() as FireDashComponent

func _ready() -> void:
	if NodeUtils.get_child_of_type(parent, TangentSpeed) == null or (NodeUtils.get_child_of_type(parent, TangentSpeed) != null and LevelManager.platformer):
		parent.path = self

func get_velocity(player: Player) -> Vector2:
	var velocity: Vector2
	var dash_orb := parent.parent as Interactable
	var angle := dash_orb.global_rotation - parent.initial_gameplay_rotation
	velocity = Vector2(player.speed.x * player.speed_multiplier, 0.0).rotated(angle)
	return velocity
