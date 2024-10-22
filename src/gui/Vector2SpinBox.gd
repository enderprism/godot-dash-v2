@tool
extends BoxContainer
class_name Vector2SpinBox

signal value_changed(new_value: Vector2)

@export var keep_aspect: bool
@onready var spinbox_x: SpinBox
@onready var spinbox_y: SpinBox
var aspect_ratio: float
var value: Vector2:
	set(new_value):
		value = new_value
		if spinbox_x == null:
			spinbox_x = TriggerSetup.get_node_or_add(self, "SpinBoxX", SpinBox, true)
		if spinbox_y == null:
			spinbox_y = TriggerSetup.get_node_or_add(self, "SpinBoxY", SpinBox, true)
		if not Engine.is_editor_hint():
			spinbox_x.set_value_no_signal(new_value.x)
			spinbox_y.set_value_no_signal(new_value.y)
		value_changed.emit(value)


func _ready() -> void:
	spinbox_x = TriggerSetup.get_node_or_add(self, "SpinBoxX", SpinBox, true)
	spinbox_y = TriggerSetup.get_node_or_add(self, "SpinBoxY", SpinBox, true)
	for spinbox in [spinbox_x, spinbox_y]:
		spinbox.allow_greater = true
		spinbox.suffix = "px"
		spinbox.custom_minimum_size.x = 128
		spinbox.alignment = HORIZONTAL_ALIGNMENT_FILL
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