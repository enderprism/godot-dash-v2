@tool
extends AbstractProperty
class_name ColorProperty

signal value_changed(value: Color)

@export var default: Color
@export var button_width: float = 100.0
@export_tool_button("Refresh") var _refresh = refresh

var label: Label
var input: ColorPickerButton
var value: set = set_value, get = get_value

func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	var spacer = NodeUtils.get_node_or_add(self, "Spacer", Control, NodeUtils.INTERNAL)
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	input = NodeUtils.get_node_or_add(self, "Input", ColorPickerButton, NodeUtils.INTERNAL)
	input.color_changed.connect(func(new_value): value_changed.emit(new_value))
	renamed.connect(refresh)
	refresh()

func set_value(new_value: Color) -> void:
	input.set_pick_color(new_value)
	value_changed.emit(new_value)

func set_value_no_signal(new_value: Color) -> void:
	input.set_pick_color(new_value)

func get_value() -> Color:
	return input.get_pick_color()

func reset() -> void:
	set_value(default)

func refresh() -> void:
	label.text = name
	input.custom_minimum_size.x = button_width
	if Engine.is_editor_hint():
		reset()

func set_input_state(enabled: bool) -> void:
	input.disabled = not enabled
