extends Control
class_name RotateGizmo

signal angle_changed(degrees: float)

enum RotationState {
	DISABLED,
	ENABLED,
	FORCED,
}

const DIVISORS_OF_360 := [0.001, 1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 18, 20, 24, 30, 36, 40, 45, 60, 72, 90, 120, 180, 360]

@export var radius: float = 128.0
@export var handle_radius: float = 8.0

@onready var default_font := ThemeDB.get_project_theme().default_font
@onready var handle_position: Vector2 = Vector2.RIGHT * radius
@onready var input_panel: Panel = NodeUtils.get_node_or_add(self, "Input panel", Panel, NodeUtils.INTERNAL)
@onready var snap_interval_input: FloatProperty = NodeUtils.get_node_or_add(self, "Snap interval", FloatProperty, NodeUtils.INTERNAL)
@onready var angle_input: SpinBox = NodeUtils.get_node_or_add(self, "Angle", SpinBox, NodeUtils.INTERNAL)

var rotating: RotationState
var handle_hovered: bool
var tween: Tween
var scale_multiplier: float
var quick_rotation: bool
var quick_rotation_is_first_frame: bool
var quick_rotation_initial_angle: float


func _ready() -> void:
	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, ^"scale_multiplier", 1.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, ^"modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	input_panel.material = preload("res://resources/SimpleBlurMaterial.tres")
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
	# Quick rotation
	if quick_rotation:
		snap_interval_input.set_value_no_signal(0.001)
		tween.kill()
		scale_multiplier = 1.0
		modulate.a = 1.0
		rotating = RotationState.FORCED
		input_panel.hide()
		angle_input.hide()
		snap_interval_input.hide()
		quick_rotation_is_first_frame = true


func _process(_delta: float) -> void:
	handle_hovered = get_local_mouse_position().distance_to(handle_position) - handle_radius < 0
	angle_input.position = Vector2.RIGHT * radius * 1.3 + Vector2.UP * angle_input.size.y * 0.5
	snap_interval_input.position = Vector2.RIGHT * radius * 1.3 + Vector2.UP * snap_interval_input.size.y * 0.5 + Vector2.UP * angle_input.size.y
	input_panel.position = snap_interval_input.position + (Vector2.LEFT + Vector2.UP) * 10.0
	input_panel.size = angle_input.position - input_panel.position + angle_input.size + (Vector2.RIGHT + Vector2.DOWN) * 10.0
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if handle_hovered:
			rotating = RotationState.ENABLED
		if rotating == RotationState.FORCED:
			rotating = RotationState.DISABLED
	if rotating == RotationState.FORCED:
		snap_interval_input.set_value_no_signal(45.0 if Input.is_key_pressed(KEY_CTRL) else 0.001)
	if rotating:
		var previous_handle_position = handle_position
		if quick_rotation_is_first_frame:
			quick_rotation_is_first_frame = false
			quick_rotation_initial_angle = get_local_mouse_position().angle()
		else:
			handle_position = Vector2.RIGHT.rotated(
				snappedf(
					get_local_mouse_position().angle() - quick_rotation_initial_angle,
					deg_to_rad(snap_interval_input.get_value()/2)
				)
			) * radius
		angle_changed.emit(rad_to_deg(handle_position.angle() - previous_handle_position.angle()))
		angle_input.set_value_no_signal(rad_to_deg(handle_position.angle()))
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and rotating == RotationState.ENABLED:
		rotating = RotationState.DISABLED
	if get_viewport().get_camera_2d() != null:
		scale.x = 1/get_viewport().get_camera_2d().zoom.x
		scale.y = 1/get_viewport().get_camera_2d().zoom.y
		scale *= scale_multiplier
	else:
		scale = Vector2.ONE * scale_multiplier
	queue_redraw()


func _draw() -> void:
	var outline_color := Color.BLACK
	outline_color.a = 0.5
	draw_gizmo(outline_color, true)
	draw_gizmo(Color.WHITE)


func draw_gizmo(color: Color, outline: bool = false) -> void:
	draw_circle(Vector2.ZERO, radius, color, false, 1.0 if not outline else 6.0)
	var handle_color = color
	if handle_hovered:
		handle_color.a /= 2
	if rotating:
		handle_color.a /= 2
	if outline:
		draw_circle(handle_position, handle_radius, handle_color, false, 6.0)
	else:
		draw_circle(handle_position, handle_radius, handle_color, true)
	# Snap tick marks
	var snap_interval := snap_interval_input.get_value()
	if snap_interval < 5.0:
		return
	var snap_ticks := PackedVector2Array()
	for i in 360.0/snap_interval:
		var if_outline := 0.0 if not outline else 3.0
		# Full
		var tick_angle := deg_to_rad(i * snap_interval)
		var tick_vector := Vector2.from_angle(tick_angle)
		var tick_start := tick_vector * radius - tick_vector * (10.0 + if_outline)
		var tick_end := tick_vector * radius + tick_vector * (10.0 + if_outline)
		snap_ticks.append(tick_start)
		snap_ticks.append(tick_end)
		# Half
		var tick_angle_half := deg_to_rad((i + 0.5) * snap_interval)
		var tick_vector_half := Vector2.from_angle(tick_angle_half)
		var tick_start_half := tick_vector_half * radius - tick_vector_half * (5.0 + if_outline)
		var tick_end_half := tick_vector_half * radius + tick_vector_half * (5.0 + if_outline)
		snap_ticks.append(tick_start_half)
		snap_ticks.append(tick_end_half)
	draw_multiline(snap_ticks, color, 1.0 if not outline else 6.0)


func _on_angle_input_value_changed(degrees: float) -> void:
	angle_changed.emit(degrees - rad_to_deg(handle_position.angle()))
	handle_position = Vector2.from_angle(deg_to_rad(degrees)) * radius
	queue_redraw()
