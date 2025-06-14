@tool
extends AbstractProperty
class_name FloatSliderProperty

signal value_changed(value: float)

@export var default: float
@export var min_value: float
@export var max_value: float = 100.0
@export var step: float
@export var rounded: bool
@export var allow_lesser: bool
@export var allow_greater: bool
@export var prefix: String
@export var suffix: String
@export var slider_width: float = 100.0
@export_tool_button("Refresh") var _refresh = refresh

var label: Label
var input: HSliderSpinBoxCombo
var value: set = set_value, get = get_value

func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	var spacer = NodeUtils.get_node_or_add(self, "Spacer", Control, NodeUtils.INTERNAL)
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	input = NodeUtils.get_node_or_add(self, "Input", HSliderSpinBoxCombo, NodeUtils.INTERNAL)
	input.value_changed.connect(func(new_value): value_changed.emit(new_value))
	renamed.connect(refresh)
	var line_edit = input.spinbox.get_line_edit()
	line_edit.text_submitted.connect(submitted_release_focus)
	line_edit.editing_toggled.connect(unedit_release_focus)
	refresh()

func set_value(new_value: float) -> void:
	input.set_value_no_signal(new_value)
	value_changed.emit(new_value)

func set_value_no_signal(new_value: float) -> void:
	input.set_value_no_signal(new_value)

func get_value() -> float:
	return input.get_value()

func reset() -> void:
	input.set_value_no_signal(default)

func refresh() -> void:
	label.text = name
	input.min_value = min_value
	input.max_value = max_value
	input.step = step
	input.rounded = rounded
	input.allow_greater = allow_greater
	input.allow_lesser = allow_lesser
	input.prefix = prefix
	input.suffix = suffix
	input.select_all_on_focus = true
	input.slider_width = slider_width
	input.update_internals()
	if Engine.is_editor_hint():
		reset()

func set_input_state(enabled: bool) -> void:
	input.editable = enabled
