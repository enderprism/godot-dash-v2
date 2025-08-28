extends Component
class_name GravityChangerComponent

enum FlipState {
	DOWN,
	UP,
	FLIP,
}

@export var flip_state := FlipState.DOWN

func _ready() -> void:
	super()
	parent.interacted.connect(set_gravity)

func set_gravity(player: Player) -> void:
	match flip_state:
		FlipState.DOWN:
			player.gravity_flip = 1
		FlipState.UP:
			player.gravity_flip = -1
		FlipState.FLIP:
			player.gravity_flip *= -1


