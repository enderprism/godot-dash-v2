@tool
extends PanelContainer
class_name Heading

@export var label_settings: LabelSettings
@export var alignment: HorizontalAlignment:
	set(value):
		alignment = value
		if label:
			label.horizontal_alignment = value
			_refresh_text()

var margin_container: MarginContainer
var label: Label

func _ready() -> void:
	margin_container = NodeUtils.get_node_or_add(self, "MarginContainer", MarginContainer, true, false)
	label = NodeUtils.get_node_or_add(margin_container, "Label", Label, true, false)
	_refresh_text()
	renamed.connect(_refresh_text)
	label_settings.changed.connect(_refresh_text)
	label.horizontal_alignment = alignment

func _refresh_text() -> void:
	label.text = name
	label.label_settings = label_settings
	var margin_width: int = int(10 * label_settings.font_size * 1.0/16.0)
	custom_minimum_size.y = 2 * (label_settings.font_size + 1)
	margin_container.add_theme_constant_override("margin_left", margin_width)
	margin_container.add_theme_constant_override("margin_right", margin_width)
	margin_container.add_theme_constant_override("margin_top", 0)
	margin_container.add_theme_constant_override("margin_bottom", 0)
