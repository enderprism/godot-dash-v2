@tool
extends AbstractProperty
class_name Vector2Property

signal value_changed(value: float)

@export var default: Vector2
@export var min_value: float
@export var max_value: float = 100.0
@export var step: float = 0.001
@export var rounded: bool
@export var allow_lesser: bool
@export var allow_greater: bool
@export var prefix: String
@export var suffix: String
@export var keep_aspect: bool
@export var expand_to_text_length: bool
@export var vertical_property: bool = true
@export_tool_button("Refresh") var _refresh = refresh

var label: Label
var input: Vector2SpinBox

func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	var spacer = NodeUtils.get_node_or_add(self, "Spacer", Control, NodeUtils.INTERNAL)
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	input = NodeUtils.get_node_or_add(self, "Input", Vector2SpinBox, NodeUtils.INTERNAL)
	input.value_changed.connect(func(new_value): value_changed.emit(new_value))
	renamed.connect(refresh)
	refresh()
	if _value == null:
		reset()
	NodeUtils \
		.get_node_or_add(self, "PropertyReset", PropertyReset, NodeUtils.INTERNAL) \
		.set_input(input)

func set_value(new_value: Vector2) -> void:
	_value = new_value
	input.set_value_no_signal(new_value)
	value_changed.emit(new_value)

func set_value_no_signal(new_value: Vector2) -> void:
	_value = new_value
	input.set_value_no_signal(new_value)

func get_value() -> Vector2:
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
	input.keep_aspect = keep_aspect
	input.vertical = vertical_property
	input.update_internals()
	if Engine.is_editor_hint():
		reset()

func set_input_state(enabled: bool) -> void:
	input.editable = enabled
