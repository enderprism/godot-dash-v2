@tool
extends AbstractProperty
class_name FileProperty

signal value_changed(value: String)

@export var default: String
@export var filetype_filters: PackedStringArray
@export var load_root: String
@export var import_to: String
@export_tool_button("Refresh") var _refresh = refresh

var label: Label
var input: MenuButton

func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	var spacer = NodeUtils.get_node_or_add(self, "Spacer", Control, NodeUtils.INTERNAL)
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	input = NodeUtils.get_node_or_add(self, "Input", MenuButton, NodeUtils.INTERNAL)
	input.flat = false
	var popup := input.get_popup() as PopupMenu
	popup.clear()
	popup.add_item("Load")
	popup.add_item("Import and load")
	popup.index_pressed.connect(_on_input_pressed)
	renamed.connect(refresh)
	refresh()
	if _value == "":
		reset()
	NodeUtils \
		.get_node_or_add(self, "PropertyReset", PropertyReset, NodeUtils.INTERNAL) \
		.set_input(input)

func set_value(new_value: String) -> void:
	_value = new_value
	input.text = "    Load…    " if new_value.is_empty() or Engine.is_editor_hint() \
			else new_value.get_file()
	value_changed.emit(new_value)

func set_value_no_signal(new_value: String) -> void:
	_value = new_value
	input.text = "    Load…    " if new_value.is_empty() or Engine.is_editor_hint() \
			else new_value.get_file()

func get_value() -> String:
	return _value

func reset() -> void:
	set_value("")

func refresh() -> void:
	label.text = name
	if Engine.is_editor_hint():
		reset()

func set_input_state(enabled: bool) -> void:
	input.disabled = not enabled

func _on_input_pressed(index: int) -> void:
	var file_path: String
	match index:
		0: # Load
			Files.load(filetype_filters, load_root)
		1: # Import and load
			Files.import_and_load(filetype_filters, "", import_to, Files.SINGLE_FILE)
	file_path = await Files.file_loaded
	if not file_path.is_empty():
		set_value(file_path)
