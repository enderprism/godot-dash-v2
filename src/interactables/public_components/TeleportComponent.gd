@tool
extends Component
class_name TeleportComponent


enum Axis {
	BOTH,
	X,
	Y,
}

@export var target: Node2D:
	set(value):
		target = value
		$"../TargetLink".target = value
@export var restrict_axis: Axis
@export var redirect_velocity: bool:
	set(value):
		redirect_velocity = value
		notify_property_list_changed()
## Multiplier for the redirected velocity.
@export var redirect_multiplier: float = 1.0
@export var override_velocity: bool:
	set(value):
		override_velocity = value
		notify_property_list_changed()
@export var new_velocity: Vector2
@export var new_velocity_axes: Axis


func _validate_property(property: Dictionary) -> void:
	if property.name == "override_velocity" and redirect_velocity:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "redirect_multiplier" and not redirect_velocity:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "redirect_velocity" and override_velocity:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["new_velocity", "new_velocity_axes"] and override_velocity == false:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _ready() -> void:
	super()
	if redirect_velocity:
		parent.collision_layer |= 1 << 10 # Velocity redirectors
	if parent is OrbInteractable:
		parent.pressed.connect(teleport)
	else:
		parent.body_entered.connect(teleport)
	$"../TargetLink".visible = LevelManager.in_editor

func teleport(player: Player):
	if target != null:
		match restrict_axis:
			Axis.BOTH:
				player.global_position = target.global_position
			Axis.X:
				player.global_position.x = target.global_position.x
			Axis.Y:
				player.global_position.y = target.global_position.y
	if redirect_velocity:
		var local_velocity_to_entrance := player.velocity.rotated(-parent.global_rotation)
		local_velocity_to_entrance.y *= -1
		var local_velocity_to_exit := local_velocity_to_entrance.rotated(target.global_rotation)
		player.velocity = local_velocity_to_exit
	elif override_velocity:
		match new_velocity_axes:
			Axis.BOTH:
				player.velocity = new_velocity.rotated(player.gameplay_rotation)
			Axis.X:
				player.velocity = Vector2(
						new_velocity.x,
						player.velocity.rotated(-player.gameplay_rotation).y,
				).rotated(player.gameplay_rotation)
			Axis.Y:
				player.velocity = Vector2(
						player.velocity.rotated(-player.gameplay_rotation).x,
						new_velocity.y,
				).rotated(player.gameplay_rotation)
