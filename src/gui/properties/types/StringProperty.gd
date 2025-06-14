@tool
extends AbstractProperty
class_name StringProperty

signal value_changed(value: String)

@export var default: String
@export var placeholder: String
@export var select_all_on_focus: bool
@export var lineedit_width: float = 100.0
@export_tool_button("Refresh") var _refresh = refresh

var label: Label
var input: LineEdit
var value: set = set_value, get = get_value

func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	var spacer = NodeUtils.get_node_or_add(self, "Spacer", Control, NodeUtils.INTERNAL)
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	input = NodeUtils.get_node_or_add(self, "Input", LineEdit, NodeUtils.INTERNAL)
	input.text_submitted.connect(func(new_value): value_changed.emit(new_value))
	input.text_submitted.connect(submitted_release_focus)
	input.editing_toggled.connect(unedit_release_focus)
	renamed.connect(refresh)
	refresh()

func set_value(new_value: String) -> void:
	input.set_text(new_value)
	value_changed.emit(new_value)

func set_value_no_signal(new_value: String) -> void:
	input.set_text(new_value)

func get_value() -> String:
	return input.get_text()

func reset() -> void:
	input.set_value_no_signal(default)

func refresh() -> void:
	label.text = name
	input.custom_minimum_size.x = lineedit_width
	input.placeholder_text = placeholder
	input.select_all_on_focus = select_all_on_focus
	if Engine.is_editor_hint():
		reset()

func set_input_state(enabled: bool) -> void:
	input.editable = enabled
