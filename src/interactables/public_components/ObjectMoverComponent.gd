extends Component
class_name ObjectMoverComponent

const CELLS_TO_PX := Vector2(LevelManager.CELL_SIZE, -LevelManager.CELL_SIZE)

enum Mode {
	ADD,
	SET,
	MOVE_TOWARDS,
}

@export var mode: Mode = Mode.ADD:
	set(value):
		mode = value
		notify_property_list_changed()
@export var position: Vector2 ## New position in units.
@export_group("Move Towards")
@export var move_towards: Node2D
@export var group_center: Node2D
## Multiplies the target distance between each object in the group. [br][br]
## [b]Examples:[/b] [br]
##   •  [code]0.0[/code]: the group's objects will all move towards the target object. [br]
##   •  [code]1.0[/code]: the group's objects will follow the target object but [b]keep[/b] their relative distance to it. [br]
##   •  [code]2.0[/code]: the group's objects will follow the target object but [b]double[/b] their relative distance to it. [br]
##   •  [code]-1.0[/code]: the group's objects will follow the target object but [b]invert[/b] their relative distance to it.
@export_range(0.0, 2.0, 0.05, "or_greater", "or_less") var distance_multiplier: float = 1.0
@export var offset: Vector2 ## Offset in global coordinates in units from the move target.

var initial_global_positions: Dictionary[Node2D, Vector2]
var initial_distances: Dictionary[Node2D, Vector2]
var group_objects: Array[Node2D]


func _ready() -> void:
	super()
	await require([TargetGroupComponent, EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name in ["move_towards", "group_center", "offset", "distance_multiplier"] and mode != Mode.MOVE_TOWARDS:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "position" and mode == Mode.MOVE_TOWARDS:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func start(_player: Player) -> void:
	group_objects.assign(get_tree() \
			.get_nodes_in_group(parent.query(TargetGroupComponent).target_group) \
			.filter(func(object): return object is Node2D))
	group_objects.map(func(object): initial_global_positions.set(object, object.global_position))
	if group_objects.is_empty():
		Toasts.warning("In %s: target group doesn't contain any objects" % parent.name)
	if mode == Mode.MOVE_TOWARDS:
		if move_towards:
			group_objects.map(func(object): initial_distances.set(object, move_towards.global_position - object.global_position))
		elif LevelManager.in_editor:
			Toasts.error("In %s: move towards is unset" % parent.name)


func _on_easing_progressed(weight_delta: float) -> void:
	for group_object in group_objects:
		var initial_global_position = initial_global_positions[group_object]
		match mode:
			Mode.ADD:
				group_object.global_position += position * CELLS_TO_PX * weight_delta
			Mode.SET:
				group_object.global_position += (parent.to_global(position * CELLS_TO_PX) - initial_global_position) * weight_delta
			Mode.MOVE_TOWARDS:
				if move_towards == null:
					return
				var initial_distance := initial_distances[group_object]
				# FIXME: doesn't work when `move_towards` is moving
				group_object.global_position += (move_towards.global_position - initial_global_position
						+ initial_distance * -distance_multiplier
						+ offset * CELLS_TO_PX) * weight_delta


