extends Component
class_name GravityChangerComponent

enum Gravity {
	DOWN,
	UP,
	FLIP,
}

@export var gravity := Gravity.DOWN

func _ready() -> void:
	if parent is OrbInteractable:
		parent.pressed.connect(set_gravity)
	else:
		parent.body_entered.connect(set_gravity)

func set_gravity(player: Player):
	match gravity:
		Gravity.DOWN:
			player.gravity_multiplier = 1
		Gravity.UP:
			player.gravity_multiplier = -1
		Gravity.FLIP:
			player.gravity_multiplier *= -1


