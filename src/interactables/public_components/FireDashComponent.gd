extends Component
class_name FireDashComponent

# TODO figure out how to make cyan dash orbs work
## Dash orbs _completely_ override the player's velocity.

var path: Node
var initial_gameplay_rotation: float
var initial_horizontal_direction: int
var angle: float

func _ready() -> void:
	$"../DashOrbPreview".visible = LevelManager.in_editor
	parent.pressed.connect(start)

func start(player: Player) -> void:
	player.dash_control = self
	initial_gameplay_rotation = player.gameplay_rotation
	if LevelManager.platformer:
		player.horizontal_direction = sign(cos(parent.global_rotation - initial_gameplay_rotation) * parent.scale.y)
	initial_horizontal_direction = player.horizontal_direction
	if LevelManager.platformer:
		angle = pingpong(parent.global_rotation, PI/2) * sign(parent.global_rotation_degrees)
	else:
		angle = -clampf(pingpong(parent.global_rotation - PI/2, PI) - PI/2, deg_to_rad(-70), deg_to_rad(70))
	player.get_node("DashParticles").emitting = true
	player.get_node("DashFlame").show()
	player.get_node("DashFlame").rotation = angle * player.horizontal_direction
	player.get_node("DashFlame").scale.x = abs(player.get_node("DashFlame").scale.x) * player.horizontal_direction
	# player.get_node("DashFlame").scale.y = sign(player.gravity_multiplier)
	if not parent.no_effects:
		var dash_boom = player.DASH_BOOM.instantiate()
		dash_boom.position = player.to_local(parent.global_position)
		player.add_child(dash_boom)
