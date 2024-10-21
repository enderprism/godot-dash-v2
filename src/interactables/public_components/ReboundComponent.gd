extends Component
class_name ReboundComponent

var _velocity: float
var sprite: Node2D
var player_distance: float

func _physics_process(delta: float) -> void:
	var player_velocity := LevelManager.player.velocity.rotated(-LevelManager.player.gameplay_rotation) \
			* LevelManager.player.gravity_multiplier
	if parent.global_position.distance_to(LevelManager.player.global_position) > Player.TERMINAL_VELOCITY.y * 2 * delta:
		_velocity = player_velocity.y
	if player_velocity.y < 0:
		player_distance = (parent.global_position.rotated(-LevelManager.player.gameplay_rotation).y) \
			- LevelManager.player.global_position.rotated(-LevelManager.player.gameplay_rotation).y \
			* LevelManager.player.gravity_multiplier
	sprite.factor = clampf(player_distance/700, 0, 1)

func get_velocity(player: Player) -> float:
	# Not compatible with dual (can't choose which player to track dynamically so it'll track P1)
	return -_velocity * player.gravity_multiplier