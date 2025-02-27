@tool
extends Component
class_name TeleportComponent

enum IgnoreAxis {
	NONE,
	X,
	Y,
}

enum NewVelocityAxes {
	BOTH,
	X,
	Y,
}

@export var target: Node2D:
	set(value):
		target = value
		$"../TargetLink".target = value
@export var ignore_axis: IgnoreAxis
@export var override_velocity: bool:
	set(value):
		override_velocity = value
		notify_property_list_changed()
@export var new_velocity: Vector2
@export var new_velocity_axes: NewVelocityAxes


func _validate_property(property: Dictionary) -> void:
	if property.name in ["new_velocity", "new_velocity_axes"] and override_velocity == false:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _ready() -> void:
	super()
	if parent is OrbInteractable:
		parent.pressed.connect(teleport)
	else:
		parent.body_entered.connect(teleport)
	$"../TargetLink".visible = LevelManager.in_editor

func teleport(player: Player):
	if target != null:
		match ignore_axis:
			IgnoreAxis.NONE:
				player.global_position = target.global_position
			IgnoreAxis.X:
				player.global_position.x = target.global_position.x
			IgnoreAxis.Y:
				player.global_position.y = target.global_position.y
	if override_velocity:
		match new_velocity_axes:
			NewVelocityAxes.BOTH:
				player.velocity = new_velocity.rotated(player.gameplay_rotation)
			NewVelocityAxes.X:
				player.velocity = Vector2(
						new_velocity.x,
						player.velocity.rotated(-player.gameplay_rotation).y,
				).rotated(player.gameplay_rotation)
			NewVelocityAxes.Y:
				player.velocity = Vector2(
						player.velocity.rotated(-player.gameplay_rotation).x,
						new_velocity.y,
				).rotated(player.gameplay_rotation)