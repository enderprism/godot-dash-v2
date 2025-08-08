extends Control
class_name RotateGizmo

signal angle_changed(degrees: float)

const DIVISORS_OF_360 := [0.001, 1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 18, 20, 24, 30, 36, 40, 45, 60, 72, 90, 120, 180, 360]

@export var radius: float = 128.0
@export var handle_radius: float = 8.0

@onready var default_font := ThemeDB.get_project_theme().default_font
@onready var handle_position: Vector2 = Vector2.RIGHT * radius
@onready var angle_input: SpinBox = NodeUtils.get_node_or_add(self, "Angle", SpinBox, NodeUtils.INTERNAL)
@onready var snap_interval_input: FloatProperty = NodeUtils.get_node_or_add(self, "Snap interval", FloatProperty, NodeUtils.INTERNAL)

var rotating: bool
var handle_hovered: bool


func _ready() -> void:
	# Angle
	angle_input.value_changed.connect(_on_angle_input_value_changed)
	angle_input.suffix = "°"
	angle_input.min_value = -180.0
	angle_input.max_value = 180.0
	angle_input.step = 0.001
	angle_input.custom_arrow_step = 1.0
	angle_input.select_all_on_focus = true
	angle_input.custom_minimum_size.x = 196.0
	var line_edit := angle_input.get_line_edit()
	line_edit.add_theme_font_size_override("font_size", 32)
	line_edit.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Snap interval
	snap_interval_input.set_value_no_signal(45)
	snap_interval_input.value_changed.connect(func(value): snap_interval_input.set_value_no_signal(DIVISORS_OF_360[DIVISORS_OF_360.bsearch(value)]))
	snap_interval_input.suffix = "°"
	snap_interval_input.step = 0.001
	snap_interval_input.min_value = 0.001
	snap_interval_input.max_value = 360.0
	snap_interval_input.refresh()


func _process(_delta: float) -> void:
	handle_hovered = get_local_mouse_position().distance_to(handle_position) - handle_radius < 0
	angle_input.position = Vector2.RIGHT * radius * 1.2 + Vector2.UP * angle_input.size.y * 0.5
	snap_interval_input.position = Vector2.RIGHT * radius * 1.2 + Vector2.UP * snap_interval_input.size.y * 0.5 + Vector2.UP * angle_input.size.y
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and handle_hovered:
		rotating = true
	if rotating:
		var previous_handle_position = handle_position
		handle_position = Vector2.RIGHT.rotated(
			snappedf(
				get_local_mouse_position().angle(),
				deg_to_rad(snap_interval_input.get_value()/2)
			)
		) * radius
		angle_changed.emit(rad_to_deg(handle_position.angle() - previous_handle_position.angle()))
		angle_input.set_value_no_signal(rad_to_deg(handle_position.angle()))
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		rotating = false
	if get_viewport().get_camera_2d() != null:
		scale.x = 1/get_viewport().get_camera_2d().zoom.x
		scale.y = 1/get_viewport().get_camera_2d().zoom.y
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color.WHITE, false, -1.0)
	var corrected_handle_radius := handle_radius
	draw_circle(handle_position, corrected_handle_radius, Color.DARK_GRAY if rotating else Color.LIGHT_GRAY if handle_hovered else Color.WHITE, true)
	# Snap tick marks
	var snap_interval := snap_interval_input.get_value()
	if snap_interval < 5.0:
		return
	var snap_ticks := PackedVector2Array()
	for i in 360.0/snap_interval:
		# Full
		var tick_angle := deg_to_rad(i * snap_interval)
		var tick_vector := Vector2.from_angle(tick_angle)
		var tick_start := tick_vector * radius - tick_vector * 10.0
		var tick_end := tick_vector * radius + tick_vector * 10.0
		snap_ticks.append(tick_start)
		snap_ticks.append(tick_end)
		# Half
		var tick_angle_half := deg_to_rad((i + 0.5) * snap_interval)
		var tick_vector_half := Vector2.from_angle(tick_angle_half)
		var tick_start_half := tick_vector_half * radius - tick_vector_half * 5.0
		var tick_end_half := tick_vector_half * radius + tick_vector_half * 5.0
		snap_ticks.append(tick_start_half)
		snap_ticks.append(tick_end_half)
	draw_multiline(snap_ticks, Color.WHITE)


func _on_angle_input_value_changed(degrees: float) -> void:
	handle_position = Vector2.from_angle(deg_to_rad(degrees)) * radius
	queue_redraw()
