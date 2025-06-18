@tool
extends AbstractProperty
class_name EnumProperty

signal value_changed(value: String)

@export var default: int
@export var fields: PackedStringArray
@export_tool_button("Refresh") var _refresh = refresh

var label: Label
var input: OptionButton

func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	var spacer = NodeUtils.get_node_or_add(self, "Spacer", Control, NodeUtils.INTERNAL)
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	input = NodeUtils.get_node_or_add(self, "Input", OptionButton, NodeUtils.INTERNAL)
	input.item_selected.connect(func(new_value): value_changed.emit(new_value))
	renamed.connect(refresh)
	refresh()
	NodeUtils \
		.get_node_or_add(self, "PropertyReset", PropertyReset, NodeUtils.INTERNAL) \
		.set_input(input)

func set_value(new_value: int) -> void:
	_value = new_value
	input.selected = new_value
	value_changed.emit(new_value)

func set_value_no_signal(new_value: int) -> void:
	_value = new_value
	input.selected = new_value

func get_value() -> int:
	return input.selected

func reset() -> void:
	set_value(default)

func refresh() -> void:
	label.text = name
	input.clear()
	for field in fields:
		input.add_item(field)
	if Engine.is_editor_hint():
		reset()

func set_input_state(enabled: bool) -> void:
	input.disabled = not enabled
