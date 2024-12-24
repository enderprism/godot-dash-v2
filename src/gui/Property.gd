@tool
extends HBoxContainer
class_name Property

enum Type {
	FLOAT,
	FLOAT_SLIDER,
	BOOL,
	VECTOR2,
	STRING,
	COLOR,
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
@export var placeholder_text: String

var _label: Label
var _spacer: Control
var _input: Array[Control]


func _ready() -> void:
	# Setup
	custom_minimum_size.y = 32
	_label = NodeUtils.get_node_or_add(self, "Label", Label, true, false)
	_spacer = NodeUtils.get_node_or_add(self, "Spacer", Control, true, false)
	_spacer.size_flags_horizontal = SIZE_FILL | SIZE_EXPAND
	# Input types
	# FLOAT
	_input.insert(Type.FLOAT, NodeUtils.get_node_or_add(self, "FLOAT", SpinBox, true, false))
	_input[Type.FLOAT].min_value = _min
	_input[Type.FLOAT].max_value = _max
	_input[Type.FLOAT].step = step
	_input[Type.FLOAT].rounded = rounded
	# FLOAT_SLIDER
	_input.insert(Type.FLOAT_SLIDER, NodeUtils.get_node_or_add(self, "FLOAT_SLIDER", HSliderSpinBoxCombo, true, false))
	_input[Type.FLOAT_SLIDER]._min = _min
	_input[Type.FLOAT_SLIDER]._max = _max
	_input[Type.FLOAT_SLIDER].step = step
	_input[Type.FLOAT_SLIDER].rounded = rounded
	_input[Type.FLOAT_SLIDER].slider_width = 100
	# BOOL
	_input.insert(Type.BOOL, NodeUtils.get_node_or_add(self, "BOOL", CheckBox, true, false))
	# VECTOR2
	_input.insert(Type.VECTOR2, NodeUtils.get_node_or_add(self, "VECTOR2", Vector2SpinBox, true, false))
	_input[Type.VECTOR2].vertical = true
	# STRING
	_input.insert(Type.STRING, NodeUtils.get_node_or_add(self, "STRING", LineEdit, true, false))
	_input[Type.STRING].custom_minimum_size.x = 100
	# COLOR
	_input.insert(Type.COLOR, NodeUtils.get_node_or_add(self, "COLOR", ColorPickerButton, true, false))
	_input[Type.COLOR].custom_minimum_size.x = 100

	for child in _input:
		child.hide()
		child.theme = preload("res://resources/NoFocusColor.tres")
	# Refresh
	_refresh()
	renamed.connect(_refresh)

func _validate_property(property: Dictionary) -> void:
	if property.name in ["_min", "_max", "step", "rounded", "or_greater", "or_less"] \
			and type not in [Type.FLOAT, Type.FLOAT_SLIDER]:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "placeholder_text" and type != Type.STRING:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _refresh() -> void:
	# Label refresh
	if _label != null:
		_label.text = name
	# Input type refresh
	for i in range(len(_input)):
		_input[i].visible = i == int(type)
