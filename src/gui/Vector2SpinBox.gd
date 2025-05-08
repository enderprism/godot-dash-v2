@tool
extends BoxContainer
class_name Vector2SpinBox

signal value_changed(new_value: Vector2)

@export var keep_aspect: bool
@export var rounded: bool
@export var step: float
@export var min_value: float
@export var max_value: float
@export var allow_greater: bool
@export var allow_lesser: bool
@export var prefix: String: set = _set_prefix
@export var suffix: String:
	set(value):
		suffix = value
		if not is_node_ready():
			return
		for spinbox in [spinbox_x, spinbox_y]:
			spinbox.suffix = value
@export var select_all_on_focus: bool
@export var editable: bool:
	set(value):
		editable = value
		if not is_node_ready():
			return
		for spinbox in [spinbox_x, spinbox_y]:
			spinbox.editable = value
@onready var spinbox_x: SpinBox
@onready var spinbox_y: SpinBox
@export var expand_to_text_length: bool
var aspect_ratio: float
var value: Vector2: set = _set_value


func _ready() -> void:
	spinbox_x = NodeUtils.get_node_or_add(self, "SpinBoxX", SpinBox, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
	spinbox_y = NodeUtils.get_node_or_add(self, "SpinBoxY", SpinBox, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
	spinbox_x.value_changed.connect(_set_x)
	spinbox_y.value_changed.connect(_set_y)
	update_internals()
	_set_value(value)


func update_internals() -> void:
	if keep_aspect:
		aspect_ratio = get_viewport_rect().size.x/get_viewport_rect().size.y
	for spinbox in [spinbox_x, spinbox_y]:
		spinbox.min_value = min_value
		spinbox.max_value = max_value
		spinbox.allow_greater = allow_greater
		spinbox.allow_lesser = allow_lesser
		spinbox.suffix = suffix
		spinbox.step = step
		spinbox.custom_minimum_size.x = 128
		spinbox.alignment = HORIZONTAL_ALIGNMENT_FILL
		spinbox.rounded = rounded
		spinbox.select_all_on_focus = select_all_on_focus
		spinbox.get_line_edit().expand_to_text_length = expand_to_text_length
	_set_prefix(prefix)


func _set_prefix(new_prefix: String) -> void:
	prefix = new_prefix
	if new_prefix != "":
		for spinbox in [spinbox_x, spinbox_y]:
			spinbox.prefix = value
	else:
		spinbox_x.prefix = "x:"
		spinbox_y.prefix = "y:"

func _set_value(new_value: Vector2) -> void:
	value = new_value
	if spinbox_x == null:
		spinbox_x = NodeUtils.get_node_or_add(self, "SpinBoxX", SpinBox, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
	if spinbox_y == null:
		spinbox_y = NodeUtils.get_node_or_add(self, "SpinBoxY", SpinBox, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
	if not Engine.is_editor_hint():
		spinbox_x.set_value_no_signal(new_value.x)
		spinbox_y.set_value_no_signal(new_value.y)
	value_changed.emit(value)

func _set_x(new_value: float) -> void:
	value.x = new_value
	value_changed.emit(value)
	if keep_aspect:
		value.y = new_value * 1/aspect_ratio
		spinbox_y.set_value_no_signal(value.y)


func _set_y(new_value: float) -> void:
	value.y = new_value
	value_changed.emit(value)
	if keep_aspect:
		value.x = new_value * aspect_ratio
		spinbox_x.set_value_no_signal(value.x)

func set_value_no_signal(new_value: Vector2):
	spinbox_x.set_value_no_signal(new_value.x)
	spinbox_y.set_value_no_signal(new_value.y)

