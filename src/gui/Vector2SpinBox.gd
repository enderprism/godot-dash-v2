@tool
extends BoxContainer
class_name Vector2SpinBox

signal value_changed(new_value: Vector2)

@export var suffix: String:
	set(value):
		suffix = value
		for spinbox in [spinbox_x, spinbox_y]:
			spinbox.suffix = value
@export var keep_aspect: bool
@export var rounded: bool
@onready var spinbox_x: SpinBox
@onready var spinbox_y: SpinBox
var aspect_ratio: float
var value: Vector2:
	set(new_value):
		value = new_value
		if spinbox_x == null:
			spinbox_x = NodeUtils.get_node_or_add(self, "SpinBoxX", SpinBox, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
		if spinbox_y == null:
			spinbox_y = NodeUtils.get_node_or_add(self, "SpinBoxY", SpinBox, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
		if not Engine.is_editor_hint():
			spinbox_x.set_value_no_signal(new_value.x)
			spinbox_y.set_value_no_signal(new_value.y)
		value_changed.emit(value)


func _ready() -> void:
	spinbox_x = NodeUtils.get_node_or_add(self, "SpinBoxX", SpinBox, NodeUtils.INTERNAL)
	spinbox_y = NodeUtils.get_node_or_add(self, "SpinBoxY", SpinBox, NodeUtils.INTERNAL)
	for spinbox in [spinbox_x, spinbox_y]:
		spinbox.allow_greater = true
		spinbox.suffix = suffix
		spinbox.custom_minimum_size.x = 128
		spinbox.alignment = HORIZONTAL_ALIGNMENT_FILL
		spinbox.rounded = rounded
	spinbox_x.prefix = "x: "
	spinbox_y.prefix = "y: "
	if not Engine.is_editor_hint():
		spinbox_x.value_changed.connect(_set_x)
		spinbox_y.value_changed.connect(_set_y)
	if keep_aspect:
		aspect_ratio = get_viewport_rect().size.x/get_viewport_rect().size.y
	value = value


func _set_x(new_value: float) -> void:
	value.x = new_value
	if keep_aspect:
		value.y = new_value * 1/aspect_ratio
		spinbox_y.set_value_no_signal(value.y)


func _set_y(new_value: float) -> void:
	value.y = new_value
	if keep_aspect:
		value.x = new_value * aspect_ratio
		spinbox_x.set_value_no_signal(value.x)

func set_value_no_signal(new_value: Vector2):
	spinbox_x.set_value_no_signal(new_value.x)
	spinbox_y.set_value_no_signal(new_value.y)

