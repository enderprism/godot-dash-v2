@tool
extends AbstractProperty
class_name Node2DProperty

signal value_changed(value: Node2D)

@export var default: Node2D
@export_tool_button("Refresh") var _refresh = refresh

var label: Label
var input: Button


func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	var spacer = NodeUtils.get_node_or_add(self, "Spacer", Control, NodeUtils.INTERNAL)
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	input = NodeUtils.get_node_or_add(self, "Input", Button, NodeUtils.INTERNAL)
	input.pressed.connect(_on_input_pressed)
	renamed.connect(refresh)
	refresh()
	if _value == null:
		reset()
	NodeUtils \
		.get_node_or_add(self, "PropertyReset", PropertyReset, NodeUtils.INTERNAL) \
		.set_input(input)


func set_value(new_value: Node2D) -> void:
	set_value_no_signal(new_value)
	value_changed.emit(_value)


func set_value_no_signal(new_value: Node2D) -> void:
	_value = new_value
	match _value:
		null:
			input.text = "    Assign…    "
		_:
			input.text = LevelManager.current_level.get_path_to(new_value)


func get_value() -> Node2D:
	return _value


func reset() -> void:
	_value = null
	input.text = "    Assign…    "
	value_changed.emit(null)


func refresh() -> void:
	label.text = name
	if Engine.is_editor_hint():
		reset()


func set_input_state(enabled: bool) -> void:
	input.disabled = not enabled


func _on_input_pressed() -> void:
	var clipboard := LevelManager.editor_clipboard
	if len(clipboard) > 1:
		return
	if clipboard.is_empty() or Engine.is_editor_hint():
		reset()
	else:
		set_value(LevelManager.current_level.get_node(clipboard[0]))
