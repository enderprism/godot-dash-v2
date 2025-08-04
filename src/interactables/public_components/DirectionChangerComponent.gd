extends Component
class_name DirectionChangerComponent

enum Direction {
	KEEP,
	FLIP,
	FORWARDS,
	BACKWARDS,
}

@export var direction := Direction.KEEP

func _ready() -> void:
	super()
	if parent is OrbInteractable:
		parent.pressed.connect(set_direction)
	else:
		parent.body_entered.connect(set_direction)

func set_direction(player: Player):
	if not LevelManager.platformer:
		match direction:
			Direction.FLIP:
				player.horizontal_direction *= -1
			Direction.FORWARDS:
				player.horizontal_direction = 1
			Direction.BACKWARDS:
				player.horizontal_direction = -1


