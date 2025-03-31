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

var _label: Label
var _spacer: Control
var _input: Array[Control]


func _ready() -> void:
	# Setup
	custom_minimum_size.y = 32
	_label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	_spacer = NodeUtils.get_node_or_add(self, "Spacer", Control, NodeUtils.INTERNAL)
	_spacer.size_flags_horizontal = SIZE_FILL | SIZE_EXPAND
	# Input types
	# FLOAT
	_input.insert(Type.FLOAT, NodeUtils.get_node_or_add(self, "FLOAT", SpinBox, NodeUtils.INTERNAL))
	_input[Type.FLOAT].min_value = _min
	_input[Type.FLOAT].max_value = _max
	_input[Type.FLOAT].step = step
	_input[Type.FLOAT].rounded = rounded
	_input[Type.FLOAT].allow_greater = or_greater
	_input[Type.FLOAT].allow_lesser = or_less
	_input[Type.FLOAT].value_changed.connect(func(new_value): value_changed.emit(new_value))
	_input[Type.FLOAT].get_line_edit().text_submitted.connect(func(_new_value): get_viewport().gui_release_focus())
	# FLOAT_SLIDER
	_input.insert(Type.FLOAT_SLIDER, NodeUtils.get_node_or_add(self, "FLOAT_SLIDER", HSliderSpinBoxCombo, NodeUtils.INTERNAL))
	_input[Type.FLOAT_SLIDER].min_value = _min
	_input[Type.FLOAT_SLIDER].max_value = _max
	_input[Type.FLOAT_SLIDER].step = step
	_input[Type.FLOAT_SLIDER].rounded = rounded
	_input[Type.FLOAT_SLIDER].or_greater = or_greater
	_input[Type.FLOAT_SLIDER].or_less = or_less
	_input[Type.FLOAT_SLIDER].slider_width = 100
	_input[Type.FLOAT_SLIDER].value_changed.connect(func(new_value): value_changed.emit(new_value))
	_input[Type.FLOAT_SLIDER].spinbox.get_line_edit().text_submitted.connect(func(_new_value): get_viewport().gui_release_focus())
	# BOOL
	_input.insert(Type.BOOL, NodeUtils.get_node_or_add(self, "BOOL", CheckBox, NodeUtils.INTERNAL))
	_input[Type.BOOL].toggled.connect(func(toggled_on): value_changed.emit(toggled_on))
	# VECTOR2
	_input.insert(Type.VECTOR2, NodeUtils.get_node_or_add(self, "VECTOR2", Vector2SpinBox, NodeUtils.INTERNAL))
	_input[Type.VECTOR2].vertical = true
	_input[Type.VECTOR2].value_changed.connect(func(new_value): value_changed.emit(new_value))
	# STRING
	_input.insert(Type.STRING, NodeUtils.get_node_or_add(self, "STRING", LineEdit, NodeUtils.INTERNAL))
	_input[Type.STRING].custom_minimum_size.x = lineedit_width
	_input[Type.STRING].focus_mode = Control.FOCUS_CLICK
	_input[Type.STRING].text_submitted.connect(func(new_text): value_changed.emit(new_text); get_viewport().gui_release_focus())
	# COLOR
	_input.insert(Type.COLOR, NodeUtils.get_node_or_add(self, "COLOR", ColorPickerButton, NodeUtils.INTERNAL))
	_input[Type.COLOR].custom_minimum_size.x = 100
	_input[Type.COLOR].color_changed.connect(func(new_color): value_changed.emit(new_color))
	# ENUM
	_input.insert(Type.ENUM, NodeUtils.get_node_or_add(self, "ENUM", OptionButton, NodeUtils.INTERNAL))
	_input[Type.ENUM].item_selected.connect(func(new_index): value_changed.emit(new_index))
	if enum_fields != null:
		setup_enum(enum_fields)

	for child in _input:
		child.hide()
		child.theme = preload("res://resources/NoFocusColor.tres")
	# Refresh
	_refresh()
	hidden.connect(_refresh)
	renamed.connect(_refresh)

func _validate_property(property: Dictionary) -> void:
	if property.name in ["_min", "_max", "step", "rounded", "or_greater", "or_less"] \
			and type not in [Type.FLOAT, Type.FLOAT_SLIDER]:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["placeholder_text", "lineedit_width"] and type != Type.STRING:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["enum_fields"] and type != Type.ENUM:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func set_value(new_value: Variant, value_type: Type) -> void:
	# TODO add error handling when type of new_value and the value type don't match and result in invalid assignments
	match value_type:
		Type.FLOAT:
			_input[Type.FLOAT].set_value_no_signal(new_value)
		Type.FLOAT_SLIDER:
			_input[Type.FLOAT_SLIDER].set_value_no_signal(new_value)
		Type.BOOL:
			_input[Type.BOOL].set_pressed_no_signal(new_value)
		Type.VECTOR2:
			_input[Type.VECTOR2].set_value_no_signal(new_value)
		Type.STRING:
			_input[Type.STRING].set_text(new_value)
		Type.COLOR:
			_input[Type.COLOR].set_pick_color(new_value) # ColorPickerButton doesn't have a no-signal method
		Type.ENUM:
			_input[Type.ENUM].select(new_value)

func get_value(value_type: Type) -> Variant:
	match value_type:
		Type.FLOAT, Type.FLOAT_SLIDER, Type.VECTOR2:
			return _input[value_type].value
		Type.BOOL:
			return _input[Type.BOOL].pressed
		Type.STRING:
			return _input[Type.STRING].get_text()
		Type.COLOR:
			return _input[Type.COLOR].color
		Type.ENUM:
			return _input[Type.ENUM].get_selected()
		_:
			return null


func set_input_state(enabled: bool) -> void:
	_label.modulate.a = lerpf(0.3, 1.0, enabled)
	match type:
		Type.FLOAT, Type.FLOAT_SLIDER, Type.VECTOR2, Type.STRING: # LineEdit-inheriting types
			_input[type].editable = enabled
		Type.BOOL, Type.COLOR, Type.ENUM: # Button-inheriting types
			_input[type].disabled = not enabled


func set_minimum(minimum: float) -> Property:
	_min = minimum
	_input[Type.FLOAT].min_value = minimum
	_input[Type.FLOAT_SLIDER].min_value = minimum
	return self


func set_maximum(maximum: float) -> Property:
	_max = maximum
	_input[Type.FLOAT].max_value = maximum
	_input[Type.FLOAT_SLIDER].max_value = maximum
	return self


func setup_enum(fields: PackedStringArray) -> void:
	for field in fields:
		_input[Type.ENUM].add_item(field)

func _refresh() -> void:
	# Label refresh
	if _label != null:
		_label.text = name
	# Input type refresh
	for i in range(len(_input)):
		_input[i].visible = i == int(type)
	if type == Type.STRING and len(_input) > Type.STRING:
		_input[Type.STRING].placeholder_text = placeholder_text
		_input[Type.STRING].custom_minimum_size.x = lineedit_width
