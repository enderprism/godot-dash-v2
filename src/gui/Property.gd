@tool
extends BoxContainer
class_name Property

signal value_changed(value: Variant)

enum Type {
	FLOAT,
	FLOAT_SLIDER,
	BOOL,
	VECTOR2,
	STRING,
	COLOR,
	ENUM,
	NODE2D,
	FILE,
}

@export var type: Type:
	set(value):
		type = value
		notify_property_list_changed()

# SpinBox types exports
@export var _min: float
@export var _max: float = 1.0
@export var step: float = 0.05
@export var rounded: bool
@export var or_greater: bool
@export var or_less: bool
@export var prefix: String
@export var suffix: String

@export var slider_width: float = 100.0

@export var keep_aspect: bool

# LineEdit type exports
@export var lineedit_width: float = 100.0
@export var placeholder_text: String

# Enum type exports
@export var enum_fields: PackedStringArray

# File type exports
@export var filetype_filters: PackedStringArray
@export var load_root: String
@export var import_to: String

# Default values
@export var default_float: float
@export var default_bool: bool
@export var default_vector2: Vector2
@export var default_string: String
@export var default_color: Color
@export var default_enum_idx: int
@export var default_node2d_path: Node2D
@export var default_file_path: String

@export_tool_button("Refresh") var refresh_property = _refresh

const DEFAULT_VALUE_TYPES: Dictionary[Type, String] = {
	Type.FLOAT: "default_float",
	Type.FLOAT_SLIDER: "default_float",
	Type.BOOL: "default_bool",
	Type.VECTOR2: "default_vector2",
	Type.STRING: "default_string",
	Type.COLOR: "default_color",
	Type.ENUM: "default_enum_idx",
	Type.NODE2D: "default_node2d_path",
	Type.FILE: "default_file_path",
}

var _label: Label
var _spacer: Control
var gui_inputs: Array[Control]
var node_2d_ref: Node2D


func _ready() -> void:
	# Setup
	custom_minimum_size.y = 32
	set_meta("_edit_group_", true)
	_label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
	_spacer = NodeUtils.get_node_or_add(self, "Spacer", Control, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
	_spacer.size_flags_horizontal = SIZE_FILL | SIZE_EXPAND
	var emit_value_changed := func(new_value): value_changed.emit(new_value)
	var submitted_release_focus := func(_new_value): get_viewport().gui_release_focus()
	var unedit_release_focus := func(toggled_on): if not toggled_on: get_viewport().gui_release_focus()
	# Input types
	# FLOAT
	gui_inputs.insert(Type.FLOAT, NodeUtils.get_node_or_add(self, "FLOAT", SpinBox, NodeUtils.INTERNAL | NodeUtils.SET_OWNER))
	gui_inputs[Type.FLOAT].value_changed.connect(emit_value_changed)
	gui_inputs[Type.FLOAT].get_line_edit().text_submitted.connect(submitted_release_focus)
	gui_inputs[Type.FLOAT].get_line_edit().editing_toggled.connect(unedit_release_focus)
	# FLOAT_SLIDER
	gui_inputs.insert(Type.FLOAT_SLIDER, NodeUtils.get_node_or_add(self, "FLOAT_SLIDER", HSliderSpinBoxCombo, NodeUtils.INTERNAL | NodeUtils.SET_OWNER))
	gui_inputs[Type.FLOAT_SLIDER].value_changed.connect(func(new_value): value_changed.emit(new_value))
	gui_inputs[Type.FLOAT_SLIDER].spinbox.get_line_edit().text_submitted.connect(submitted_release_focus)
	gui_inputs[Type.FLOAT_SLIDER].spinbox.get_line_edit().editing_toggled.connect(unedit_release_focus)
	# BOOL
	gui_inputs.insert(Type.BOOL, NodeUtils.get_node_or_add(self, "BOOL", CheckBox, NodeUtils.INTERNAL | NodeUtils.SET_OWNER))
	gui_inputs[Type.BOOL].toggled.connect(emit_value_changed)
	# VECTOR2
	gui_inputs.insert(Type.VECTOR2, NodeUtils.get_node_or_add(self, "VECTOR2", Vector2SpinBox, NodeUtils.INTERNAL | NodeUtils.SET_OWNER))
	gui_inputs[Type.VECTOR2].value_changed.connect(emit_value_changed)
	# STRING
	gui_inputs.insert(Type.STRING, NodeUtils.get_node_or_add(self, "STRING", LineEdit, NodeUtils.INTERNAL | NodeUtils.SET_OWNER))
	gui_inputs[Type.STRING].text_submitted.connect(func(new_text): value_changed.emit(new_text); get_viewport().gui_release_focus())
	gui_inputs[Type.STRING].editing_toggled.connect(unedit_release_focus)
	# COLOR
	gui_inputs.insert(Type.COLOR, NodeUtils.get_node_or_add(self, "COLOR", ColorPickerButton, NodeUtils.INTERNAL | NodeUtils.SET_OWNER))
	gui_inputs[Type.COLOR].color_changed.connect(emit_value_changed)
	# ENUM
	gui_inputs.insert(Type.ENUM, NodeUtils.get_node_or_add(self, "ENUM", OptionButton, NodeUtils.INTERNAL | NodeUtils.SET_OWNER))
	gui_inputs[Type.ENUM].item_selected.connect(emit_value_changed)
	# NODE2D
	gui_inputs.insert(Type.NODE2D, NodeUtils.get_node_or_add(self, "NODE2D", Button, NodeUtils.INTERNAL | NodeUtils.SET_OWNER))
	gui_inputs[Type.NODE2D].pressed.connect(update_node2d)
	# FILE
	gui_inputs.insert(Type.FILE, NodeUtils.get_node_or_add(self, "FILE", MenuButton, NodeUtils.INTERNAL | NodeUtils.SET_OWNER))
	# Theme
	for child in gui_inputs:
		child.hide()
		child.theme = preload("res://resources/NoFocusColor.tres")
	# Refresh
	_refresh()
	hidden.connect(_refresh)
	renamed.connect(_refresh)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"gui_input_reset_default") \
			and gui_inputs[type].get_rect().has_point(get_local_mouse_position()):
		reset()


func _validate_property(property: Dictionary) -> void:
	if property.name in ["_min", "_max", "step", "rounded", "or_greater", "or_less", "prefix", "suffix"] \
			and type not in [Type.FLOAT, Type.FLOAT_SLIDER, Type.VECTOR2]:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "default_float" and type not in [Type.FLOAT, Type.FLOAT_SLIDER]:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "slider_width" and type != Type.FLOAT_SLIDER:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "default_bool" and type != Type.BOOL:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["default_vector2", "keep_aspect"] and type != Type.VECTOR2:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["placeholder_text", "lineedit_width", "default_string"] and type != Type.STRING:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "default_color" and type != Type.COLOR:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["enum_fields", "default_enum_idx"] and type != Type.ENUM:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "default_node2d_path" and type != Type.NODE2D:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["default_file_path", "filetype_filters", "load_root", "import_to"] and type != Type.FILE:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func set_value(new_value: Variant) -> void:
	match type:
		Type.FLOAT:
			gui_inputs[Type.FLOAT].set_value_no_signal(new_value)
		Type.FLOAT_SLIDER:
			gui_inputs[Type.FLOAT_SLIDER].set_value_no_signal(new_value)
		Type.BOOL:
			gui_inputs[Type.BOOL].set_pressed_no_signal(new_value)
		Type.VECTOR2:
			gui_inputs[Type.VECTOR2].set_value_no_signal(new_value)
		Type.STRING:
			gui_inputs[Type.STRING].set_text(new_value)
		Type.COLOR:
			gui_inputs[Type.COLOR].set_pick_color(new_value) # ColorPickerButton doesn't have a no-signal method
		Type.ENUM:
			gui_inputs[Type.ENUM].select(new_value)
		Type.NODE2D:
			if new_value == null or Engine.is_editor_hint():
				gui_inputs[Type.NODE2D].set_text("    Assign…    ")
			else:
				gui_inputs[Type.NODE2D].set_text(LevelManager.editor_edited_level.get_path_to(new_value))
			node_2d_ref = new_value
		Type.FILE:
			gui_inputs[Type.FILE].set_text("    Load…    " if new_value.is_empty() or Engine.is_editor_hint() else new_value.get_file())
			gui_inputs[Type.FILE].set_meta("file_path", new_value)


func get_value(value_type: Type = type) -> Variant:
	match value_type:
		Type.FLOAT, Type.FLOAT_SLIDER, Type.VECTOR2:
			return gui_inputs[value_type].value
		Type.BOOL:
			return gui_inputs[Type.BOOL].pressed
		Type.STRING:
			return gui_inputs[Type.STRING].get_text()
		Type.COLOR:
			return gui_inputs[Type.COLOR].color
		Type.ENUM:
			return gui_inputs[Type.ENUM].get_selected()
		Type.NODE2D:
			return gui_inputs[Type.NODE2D].get_text()
		Type.FILE:
			return gui_inputs[Type.FILE].get_meta("file_path", "")
		_:
			return null


func set_input_state(enabled: bool) -> void:
	_label.modulate.a = lerpf(0.3, 1.0, enabled)
	match type:
		Type.FLOAT, Type.FLOAT_SLIDER, Type.VECTOR2, Type.STRING: # LineEdit-inheriting types
			gui_inputs[type].editable = enabled
		Type.BOOL, Type.COLOR, Type.ENUM, Type.NODE2D: # Button-inheriting types
			gui_inputs[type].disabled = not enabled


func reset() -> void:
	set_value(get(DEFAULT_VALUE_TYPES[type]))


func update_internals() -> void:
	move_child(_label, 0)
	move_child(_spacer, 1)
	for input in [gui_inputs[Type.FLOAT], gui_inputs[Type.FLOAT_SLIDER], gui_inputs[Type.VECTOR2]]:
		input.min_value = _min
		input.max_value = _max
		input.step = step
		input.rounded = rounded
		input.allow_greater = or_greater
		input.allow_lesser = or_less
		input.prefix = prefix
		input.suffix = suffix
		input.select_all_on_focus = true
	gui_inputs[Type.FLOAT].get_line_edit().expand_to_text_length = true
	gui_inputs[Type.FLOAT_SLIDER].expand_to_text_length = true
	gui_inputs[Type.VECTOR2].expand_to_text_length = true
	gui_inputs[Type.FLOAT_SLIDER].slider_width = slider_width
	gui_inputs[Type.VECTOR2].vertical = true
	gui_inputs[Type.VECTOR2].keep_aspect = keep_aspect
	gui_inputs[Type.VECTOR2].call_deferred("update_internals")
	gui_inputs[Type.STRING].custom_minimum_size.x = lineedit_width
	gui_inputs[Type.STRING].expand_to_text_length = true
	gui_inputs[Type.STRING].focus_mode = Control.FOCUS_CLICK
	gui_inputs[Type.COLOR].custom_minimum_size.x = 100
	gui_inputs[Type.FILE].flat = false
	if enum_fields != null:
		setup_enum(enum_fields)
	if gui_inputs[Type.FILE].get_popup() != null:
		var popup := gui_inputs[Type.FILE].get_popup() as PopupMenu
		popup.clear()
		popup.add_item("Load")
		popup.add_item("Import and load")
		NodeUtils.connect_new(popup.index_pressed, update_file)


func setup_enum(fields: PackedStringArray) -> void:
	gui_inputs[Type.ENUM].clear()
	for field in fields:
		gui_inputs[Type.ENUM].add_item(field)


func update_node2d() -> void:
	var clipboard := LevelManager.editor_clipboard
	if len(clipboard) > 1:
		return
	if clipboard.is_empty() or Engine.is_editor_hint():
		gui_inputs[Type.NODE2D].set_text("    Assign…    ")
		node_2d_ref = null
	else:
		gui_inputs[Type.NODE2D].set_text(LevelManager.editor_edited_level.get_path_to(clipboard[0]))
		node_2d_ref = clipboard[0]
	value_changed.emit(node_2d_ref)


func update_file(index: int) -> void:
	var file_path: String
	match index:
		0: # Load
			Files.load(filetype_filters, load_root)
		1: # Import and load
			Files.import_and_load(filetype_filters, "", import_to, Files.SINGLE_FILE)
	file_path = await Files.file_loaded
	if not file_path.is_empty():
		set_value(file_path)
	value_changed.emit(file_path)


func _refresh() -> void:
	# Label refresh
	if _label != null:
		_label.text = name
	# Input type refresh
	for i in range(len(gui_inputs)):
		gui_inputs[i].visible = i == int(type)
	update_internals()
	if Engine.is_editor_hint():
		reset()
