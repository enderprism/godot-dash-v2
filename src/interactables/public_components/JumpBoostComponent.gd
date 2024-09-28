extends Component
class_name JumpBoostComponent

@export var jump_boost: float


func get_velocity(player: Player) -> float:
	return jump_boost * -player.speed.y * player.gameplay_trigger_gravity_multiplier * sign(player.gravity_multiplier)