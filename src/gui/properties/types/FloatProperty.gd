@tool
extends AbstractProperty
class_name FloatProperty

signal value_changed(value: float)

@export var default: float
@export var min_value: float
@export var max_value: float = 100.0
@export var step: float = 0.001
@export var rounded: bool
@export var allow_lesser: bool
@export var allow_greater: bool
@export var prefix: String
@export var suffix: String
@export_tool_button("Refresh") var _refresh = refresh

var label: Label
var input: SpinBox

func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	var spacer = NodeUtils.get_node_or_add(self, "Spacer", Control, NodeUtils.INTERNAL)
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	input = NodeUtils.get_node_or_add(self, "Input", SpinBox, NodeUtils.INTERNAL)
	input.value_changed.connect(func(new_value): value_changed.emit(new_value))
	renamed.connect(refresh)
	var line_edit = input.get_line_edit()
	line_edit.text_submitted.connect(submitted_release_focus)
	line_edit.editing_toggled.connect(unedit_release_focus)
	refresh()
	NodeUtils \
		.get_node_or_add(self, "PropertyReset", PropertyReset, NodeUtils.INTERNAL) \
		.set_input(input)

func set_value(new_value: float) -> void:
	_value = new_value
	input.set_value_no_signal(new_value)
	value_changed.emit(new_value)

func set_value_no_signal(new_value: float) -> void:
	_value = new_value
	input.set_value_no_signal(new_value)

func get_value() -> float:
	return input.get_value()

func reset() -> void:
	set_value(default)

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
	if Engine.is_editor_hint():
		reset()

func set_input_state(enabled: bool) -> void:
	input.editable = enabled
