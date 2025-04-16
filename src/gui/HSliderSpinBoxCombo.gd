@tool
extends HBoxContainer
class_name HSliderSpinBoxCombo

signal value_changed(value: float)

@export var min_value: float
@export var max_value: float = 1.0
@export var step: float = 0.05
@export var rounded: bool
@export var allow_greater: bool
@export var allow_lesser: bool
@export var prefix: String
@export var suffix: String
@export var select_all_on_focus: bool
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
	hslider = NodeUtils.get_node_or_add(self, "HSlider", HSlider, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
	hslider.custom_minimum_size.x = slider_width
	hslider.size_flags_vertical = SIZE_FILL
	spinbox = NodeUtils.get_node_or_add(self, "SpinBox", SpinBox, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
	update_internals()
	hslider.value_changed.connect(_update_value)
	spinbox.value_changed.connect(_update_value)


func update_internals() -> void:
	for _range in [hslider, spinbox]:
		_range.min_value = min_value
		_range.max_value = max_value
		_range.step = step
		_range.rounded = rounded
		_range.allow_greater = allow_greater
		_range.allow_lesser = allow_lesser
	spinbox.prefix = prefix
	spinbox.suffix = suffix
	spinbox.select_all_on_focus = select_all_on_focus


func _update_value(new_value: float) -> void:
	hslider.value = new_value
	spinbox.value = new_value
	value_changed.emit(value)

func set_value_no_signal(new_value: float) -> void:
	hslider.value = new_value
	spinbox.value = new_value
