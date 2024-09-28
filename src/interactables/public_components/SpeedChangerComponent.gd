extends Component
class_name SpeedChangerComponent

@export var speed: float

var previous_player_speed: float

func _ready() -> void:
	parent.body_entered.connect(set_speed)

func set_speed(player: Player) -> void:
	if is_zero_approx(speed):
		player.speed_0_portal_control = self
		previous_player_speed = player.speed_multiplier
	player.speed_multiplier = speed