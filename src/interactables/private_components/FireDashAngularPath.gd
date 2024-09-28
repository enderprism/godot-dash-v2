extends Node
class_name FireDashAngularPath

@onready var parent := get_parent() as FireDashComponent

func _ready() -> void:
	parent.path = self

func get_velocity(player: Player) -> Vector2:
	var velocity: Vector2
	var dash_orb := parent.parent as Interactable
	var angle := dash_orb.rotation - parent.initial_gameplay_rotation
	var direction := player.horizontal_direction if not LevelManager.platformer else int(sign(cos(dash_orb.rotation - parent.initial_gameplay_rotation)))
	if (player.is_on_floor() and sin(angle) > 0) or (player.is_on_ceiling() and sin(angle) < 0):
		velocity.y = 0
	else:
		velocity.y = tan(angle) * player.speed.x * direction * player.speed_multiplier
	velocity.x = player.speed.x * direction * player.speed_multiplier
	return velocity