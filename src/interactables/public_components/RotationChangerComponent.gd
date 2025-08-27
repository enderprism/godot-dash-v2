extends Component
class_name RotationChangerComponent

enum Mode {
	ADD,
	SET,
}

@export var mode: Mode = Mode.ADD:
	set(value):
		mode = value
		notify_property_list_changed()
@export var rotate_around_self: bool:
	set(value):
		rotate_around_self = value
		notify_property_list_changed()
@export var pivot: Node2D
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var rotation_degrees: float

var initial_global_rotations_degrees: Dictionary[Node2D, float]
var group_objects: Array[Node2D]


func _ready() -> void:
	super()
	await require([TargetGroupComponent, EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func _validate_property(property: Dictionary) -> void:
	if property.name == "rotation_degrees" and (mode != Mode.SET and mode != Mode.ADD):
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "pivot" and rotate_around_self:
		property.usage |= PROPERTY_USAGE_READ_ONLY


func start(_player: Player) -> void:
	group_objects.assign(get_tree() \
			.get_nodes_in_group(parent.query(TargetGroupComponent).target_group) \
			.filter(func(object): return object is Node2D))
	group_objects.map(func(object): initial_global_rotations_degrees.set(object, object.global_rotation))
	if group_objects.is_empty():
		Toasts.warning("In %s: target group doesn't contain any objects" % parent.name)


func _on_easing_progressed(weight_delta: float) -> void:
	for group_object in group_objects:
		var initial_global_rotation_degrees := initial_global_rotations_degrees[group_object]
		var rotation_delta: float
		match mode:
			Mode.SET:
				rotation_delta = (rotation_degrees - initial_global_rotation_degrees) * weight_delta
			Mode.ADD:
				rotation_delta = rotation_degrees * weight_delta
		_apply_rotation_delta(group_object, rotation_delta)


func _apply_rotation_delta(group_object: Node2D, rotation_delta: float) -> void:
	if rotate_around_self:
		group_object.global_rotation_degrees += rotation_delta
	elif pivot:
		group_object.global_rotation_degrees += rotation_delta
		var position_relative_to_pivot: Vector2 = group_object.global_position - pivot.global_position
		var position_delta := position_relative_to_pivot.rotated(deg_to_rad(rotation_delta)) - position_relative_to_pivot
		group_object.global_position += position_delta
