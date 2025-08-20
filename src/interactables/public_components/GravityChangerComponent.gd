extends Component
class_name GravityChangerComponent

enum Gravity {
	DOWN,
	UP,
	FLIP,
}

@export var gravity := Gravity.DOWN

func _ready() -> void:
	super()
	parent.interacted.connect(set_gravity)

func set_gravity(player: Player) -> void:
	match gravity:
		Gravity.DOWN:
			player.gravity_multiplier = 1
		Gravity.UP:
			player.gravity_multiplier = -1
		Gravity.FLIP:
			player.gravity_multiplier *= -1


