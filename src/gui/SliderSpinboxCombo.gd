@tool
extends HBoxContainer

@onready var hslider: HSlider = NodeUtils.get_child_of_type(self, HSlider)
@onready var spinbox: SpinBox = NodeUtils.get_child_of_type(self, SpinBox)

var value: float:
	get:
		if hslider != null:
			return hslider.value
		elif spinbox != null:
			return spinbox.value
		else:
			return 100 # Default value
	set(value):
		_update_value(value)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if NodeUtils.get_child_of_type(self, HSlider) == null:
		warnings.append("The control requires an HSlider to work.")
	if NodeUtils.get_child_of_type(self, SpinBox) == null:
		warnings.append("The control requires a SpinBox to work.")
	return warnings


func _ready() -> void:
	if hslider != null:
		hslider.value_changed.connect(_update_value)
	if spinbox != null:
		spinbox.value_changed.connect(_update_value)


func _update_value(new_value: float) -> void:
	hslider.value = new_value
	spinbox.value = new_value
