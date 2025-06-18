@tool
extends AbstractProperty
class_name BoolProperty

signal value_changed(value: bool)

@export var default: bool
@export_tool_button("Refresh") var _refresh = refresh

var label: Label
var input: CheckBox

func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	var spacer = NodeUtils.get_node_or_add(self, "Spacer", Control, NodeUtils.INTERNAL)
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	input = NodeUtils.get_node_or_add(self, "Input", CheckBox, NodeUtils.INTERNAL) as CheckBox
	input.toggled.connect(func(new_value): value_changed.emit(new_value))
	renamed.connect(refresh)
	refresh()
	if _value == null:
		reset()
	NodeUtils \
		.get_node_or_add(self, "PropertyReset", PropertyReset, NodeUtils.INTERNAL) \
		.set_input(input)

func set_value(new_value: bool) -> void:
	_value = new_value
	input.set_pressed_no_signal(new_value)
	value_changed.emit(new_value)

func set_value_no_signal(new_value: bool) -> void:
	_value = new_value
	input.set_value_no_signal(new_value)

func get_value() -> float:
	return input.get_value()

func reset() -> void:
	set_value(default)

func refresh() -> void:
	label.text = name
	if Engine.is_editor_hint():
		reset()

func set_input_state(enabled: bool) -> void:
	input.disabled = not enabled
