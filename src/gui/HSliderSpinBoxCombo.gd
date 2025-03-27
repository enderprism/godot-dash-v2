@tool
extends HBoxContainer
class_name HSliderSpinBoxCombo

signal value_changed(value: float)

@export var min_value: float
@export var max_value: float = 1.0
@export var step: float = 0.05
@export var rounded: bool
@export var or_greater: bool
@export var or_less: bool
@export var slider_width: float = 256.0:
	set(value):
		slider_width = value
		if hslider != null:
			hslider.custom_minimum_size.x = value

var hslider: HSlider
var spinbox: SpinBox

var value: float:
	get:
		if hslider != null:
			return hslider.value
		elif spinbox != null:
			return spinbox.value
		else:
			return 1.0 # Default value
	set(value):
		value_changed.emit(value)
		call_deferred("_update_value", value)


func _ready() -> void:
	alignment = ALIGNMENT_CENTER
	hslider = NodeUtils.get_node_or_add(self, "HSlider", HSlider, NodeUtils.INTERNAL)
	hslider.custom_minimum_size.x = slider_width
	hslider.size_flags_vertical = SIZE_FILL
	spinbox = NodeUtils.get_node_or_add(self, "SpinBox", SpinBox, NodeUtils.INTERNAL)
	for _range in [hslider, spinbox]:
		_range.min_value = min_value
		_range.max_value = max_value
		_range.step = step
		_range.rounded = rounded
		_range.allow_greater = or_greater
		_range.allow_lesser = or_less
	hslider.value_changed.connect(_update_value)
	spinbox.value_changed.connect(_update_value)


func _update_value(new_value: float) -> void:
	hslider.value = new_value
	spinbox.value = new_value
	value_changed.emit(value)

func set_value_no_signal(new_value: float) -> void:
	hslider.value = new_value
	spinbox.value = new_value
