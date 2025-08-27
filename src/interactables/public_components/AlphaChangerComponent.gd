extends Component
class_name AlphaChangerComponent

enum Mode {
	SET,
	MULTIPLY,
	DIVIDE,
	COPY,
}

@export var mode: Mode = Mode.SET:
	set(value):
		mode = value
		notify_property_list_changed()
@export_range(0.0, 1.0, 0.01) var alpha: float = 1.0
@export var copy_target: Node2D
@export_range(0.0, 1.0, 0.01, "or_greater") var copy_multiplier: float

var inital_alphas: Dictionary[Node2D, float]
var group_objects: Array[Node2D]

func _ready() -> void:
	super()
	await require([TargetGroupComponent, EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func _validate_property(property: Dictionary) -> void:
	if property.name == "alpha" and mode == Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["copy_target", "copy_multiplier"] and mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func start(_player: Player) -> void:
	group_objects.assign(get_tree() \
			.get_nodes_in_group(parent.query(TargetGroupComponent).target_group) \
			.filter(func(object): return object is Node2D) \
			.map(into_hsv_watcher))
	group_objects.map(func(object): inital_alphas.set(object, object.modulate.a))
	if mode == Mode.COPY and copy_target == null and LevelManager.in_editor:
		Toasts.new_toast("In %s: copy_target is unset!" % name, 1.0, Toasts.ERROR)


func _on_easing_progressed(weight_delta: float) -> void:
	for group_object in group_objects:
		var initial_alpha := inital_alphas[group_object]
		match mode:
			Mode.SET:
				group_object.modulate.a += (alpha - initial_alpha) * weight_delta
			Mode.MULTIPLY:
				group_object.modulate.a += (alpha * initial_alpha - initial_alpha) * weight_delta
			Mode.COPY:
				if copy_target != null:
					group_object.modulate.a += (copy_target.modulate.a * copy_multiplier - initial_alpha) * weight_delta


static func into_hsv_watcher(object: Node) -> Node:
	var hsv_watcher := object.get_node_or_null(^"HSVWatcher")
	return hsv_watcher if hsv_watcher != null else object
