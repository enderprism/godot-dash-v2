@tool
extends HBoxContainer
class_name FloatProp

signal value_changed(new_value: String)

@export var default: float
@export var _min: float
@export var _max: float = 1.0
@export var step: float = 0.05
@export var rounded: bool
@export var or_greater: bool
@export var or_less: bool
@export var prefix: String
@export var suffix: String

var label: Label
var input: SpinBox


func _ready() -> void:
	label = Label.new()
	var spacer = Control.new()
	input = SpinBox.new()
	label.text = name
	spacer.size_flags_horizontal = Control.SIZE_EXPAND
	add_child(label)
	add_child(spacer)
	add_child(input)
	renamed.connect(refresh)


func set_value(value: float) -> void:
	match input:
		null:
			push_error("Input field isn't initialized")
		_:
			input.set_value_no_signal(value)


func get_value() -> float:
	match input:
		null:
			push_error("Input field isn't initialized")
			return NAN
		_:
			return input.value


func reset() -> void:
	match input:
		null:
			push_error("Input field isn't initialized")
		_:
			input.set_value_no_signal(default)


func refresh() -> void:
	label.text = name
	if Engine.is_editor_hint():
		reset()


func set_input_state(enabled: bool) -> void:
	input.editable = enabled
