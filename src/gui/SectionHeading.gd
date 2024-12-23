@tool
extends PanelContainer
class_name SectionHeading

@export var label_settings: LabelSettings
@export var alignment: HorizontalAlignment:
	set(value):
		alignment = value
		if label:
			label.horizontal_alignment = value
			_refresh_text()
@export var section_content: Control

@onready var icon_open = preload("res://assets/textures/guis/shared/SectionHeadingFoldButtonOpen.svg")
@onready var icon_closed = preload("res://assets/textures/guis/shared/SectionHeadingFoldButtonClosed.svg")

var margin_container: MarginContainer
var label: Label
var fold_button: Button


func _ready() -> void:
	margin_container = NodeUtils.get_node_or_add(self, "MarginContainer", MarginContainer, true, false)
	label = NodeUtils.get_node_or_add(margin_container, "Label", Label, true, false)
	fold_button = NodeUtils.get_node_or_add(self, "FoldButton", Button, true, false)
	fold_button.icon = icon_open
	fold_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fold_button.flat = true
	fold_button.toggle_mode = true
	fold_button.expand_icon = true
	fold_button.toggled.connect(_fold)
	fold_button.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

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

func _fold(folded: bool) -> void:
	fold_button.icon = icon_closed if folded else icon_open
	section_content.visible = not folded
