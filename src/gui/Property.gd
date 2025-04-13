@tool
extends HBoxContainer
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
}

@export var type: Type:
	set(value):
		type = value
		notify_property_list_changed()
		call_deferred("_refresh")

# SpinBox types exports
@export var _min: float
@export var _max: float = 1.0
@export var step: float = 0.05
@export var rounded: bool
@export var or_greater: bool
@export var or_less: bool

# LineEdit type exports
@export var lineedit_width: float = 100.0
@export var placeholder_text: String

# Enum type exports
@export var enum_fields: PackedStringArray

# Default values
@export var default_float: float
@export var default_bool: bool
@export var default_vector2: Vector2
@export var default_string: String
@export var default_color: Color
@export var default_enum_idx: int
@export var default_node2d_path: String

const DEFAULT_VALUE_TYPES: Dictionary[Type, String] = {
	Type.FLOAT: "default_float",
	Type.FLOAT_SLIDER: "default_float",
	Type.BOOL: "default_bool",
	Type.VECTOR2: "default_vector2",
	Type.STRING: "default_string",
	Type.COLOR: "default_color",
	Type.ENUM: "default_enum_idx",
	Type.NODE2D: "default_node2d_path",
}

var _label: Label
var _spacer: Control
var gui_inputs: Array[Control]


func _ready() -> void:
	# Setup
	custom_minimum_size.y = 32
	_label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	_spacer = NodeUtils.get_node_or_add(self, "Spacer", Control, NodeUtils.INTERNAL)
	_spacer.size_flags_horizontal = SIZE_FILL | SIZE_EXPAND
	# Input types
	# FLOAT
	gui_inputs.insert(Type.FLOAT, NodeUtils.get_node_or_add(self, "FLOAT", SpinBox, NodeUtils.INTERNAL))
	gui_inputs[Type.FLOAT].value_changed.connect(func(new_value): value_changed.emit(new_value))
	gui_inputs[Type.FLOAT].get_line_edit().text_submitted.connect(func(_new_value): get_viewport().gui_release_focus())
	# FLOAT_SLIDER
	gui_inputs.insert(Type.FLOAT_SLIDER, NodeUtils.get_node_or_add(self, "FLOAT_SLIDER", HSliderSpinBoxCombo, NodeUtils.INTERNAL))
	gui_inputs[Type.FLOAT_SLIDER].value_changed.connect(func(new_value): value_changed.emit(new_value))
	gui_inputs[Type.FLOAT_SLIDER].spinbox.get_line_edit().text_submitted.connect(func(_new_value): get_viewport().gui_release_focus())
	# BOOL
	gui_inputs.insert(Type.BOOL, NodeUtils.get_node_or_add(self, "BOOL", CheckBox, NodeUtils.INTERNAL))
	gui_inputs[Type.BOOL].toggled.connect(func(toggled_on): value_changed.emit(toggled_on))
	# VECTOR2
	gui_inputs.insert(Type.VECTOR2, NodeUtils.get_node_or_add(self, "VECTOR2", Vector2SpinBox, NodeUtils.INTERNAL))
	gui_inputs[Type.VECTOR2].value_changed.connect(func(new_value): value_changed.emit(new_value))
	# STRING
	gui_inputs.insert(Type.STRING, NodeUtils.get_node_or_add(self, "STRING", LineEdit, NodeUtils.INTERNAL))
	gui_inputs[Type.STRING].text_submitted.connect(func(new_text): value_changed.emit(new_text); get_viewport().gui_release_focus())
	# COLOR
	gui_inputs.insert(Type.COLOR, NodeUtils.get_node_or_add(self, "COLOR", ColorPickerButton, NodeUtils.INTERNAL))
	gui_inputs[Type.COLOR].color_changed.connect(func(new_color): value_changed.emit(new_color))
	# ENUM
	gui_inputs.insert(Type.ENUM, NodeUtils.get_node_or_add(self, "ENUM", OptionButton, NodeUtils.INTERNAL))
	gui_inputs[Type.ENUM].item_selected.connect(func(new_index): value_changed.emit(new_index))
	update_internals()
	for child in gui_inputs:
		child.hide()
		child.theme = preload("res://resources/NoFocusColor.tres")
	# Refresh
	_refresh()
	hidden.connect(_refresh)
	renamed.connect(_refresh)





func _validate_property(property: Dictionary) -> void:
	if property.name in ["_min", "_max", "step", "rounded", "or_greater", "or_less"] \
			and type not in [Type.FLOAT, Type.FLOAT_SLIDER, Type.VECTOR2]:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "default_float" and type not in [Type.FLOAT, Type.FLOAT_SLIDER]:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "default_bool" and type != Type.BOOL:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "default_vector2" and type != Type.VECTOR2:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["placeholder_text", "lineedit_width", "default_string"] and type != Type.STRING:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "default_color" and type != Type.COLOR:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["enum_fields", "default_enum_idx"] and type != Type.ENUM:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "default_node2d_path" and type != Type.NODE2D:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func set_value(new_value: Variant, value_type: Type) -> void:
	# TODO add error handling when type of new_value and the value type don't match and result in invalid assignments
	match value_type:
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


func get_value(value_type: Type) -> Variant:
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
		_:
			return null


func set_input_state(enabled: bool) -> void:
	_label.modulate.a = lerpf(0.3, 1.0, enabled)
	match type:
		Type.FLOAT, Type.FLOAT_SLIDER, Type.VECTOR2, Type.STRING: # LineEdit-inheriting types
			gui_inputs[type].editable = enabled
		Type.BOOL, Type.COLOR, Type.ENUM: # Button-inheriting types
			gui_inputs[type].disabled = not enabled


func reset(value_type: Type) -> void:
	set_value(DEFAULT_VALUE_TYPES[value_type], value_type)


func update_internals() -> void:
	for input in [gui_inputs[Type.FLOAT], gui_inputs[Type.FLOAT_SLIDER], gui_inputs[Type.VECTOR2]]:
		input.min_value = _min
		input.max_value = _max
		input.step = step
		input.rounded = rounded
		input.allow_greater = or_greater
		input.allow_lesser = or_less
	gui_inputs[Type.FLOAT_SLIDER].slider_width = 100
	gui_inputs[Type.VECTOR2].vertical = true
	gui_inputs[Type.STRING].custom_minimum_size.x = lineedit_width
	gui_inputs[Type.STRING].focus_mode = Control.FOCUS_CLICK
	gui_inputs[Type.COLOR].custom_minimum_size.x = 100
	if enum_fields != null:
		setup_enum(enum_fields)


func setup_enum(fields: PackedStringArray) -> void:
	gui_inputs[Type.ENUM].clear()
	for field in fields:
		gui_inputs[Type.ENUM].add_item(field)


func _refresh() -> void:
	# Label refresh
	if _label != null:
		_label.text = name
	# Input type refresh
	for i in range(len(gui_inputs)):
		gui_inputs[i].visible = i == int(type)
	if type == Type.STRING and len(gui_inputs) > Type.STRING:
		gui_inputs[Type.STRING].placeholder_text = placeholder_text
		gui_inputs[Type.STRING].custom_minimum_size.x = lineedit_width
