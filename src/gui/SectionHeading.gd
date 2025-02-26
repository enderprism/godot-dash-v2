@tool
extends VBoxContainer
class_name SectionHeading

@export var label_settings: LabelSettings
@export var label_alignment: HorizontalAlignment:
	set(value):
		label_alignment = value
		if heading:
			heading.alignment = label_alignment
			_refresh_text()

@onready var icon_open = preload("res://assets/textures/guis/shared/SectionHeadingFoldButtonOpen.svg")
@onready var icon_closed = preload("res://assets/textures/guis/shared/SectionHeadingFoldButtonClosed.svg")

var heading: Heading
var fold_button: Button


func _ready() -> void:
	heading = Heading.new()
	heading.label_settings = label_settings
	heading.alignment = label_alignment
	add_child(heading, false, INTERNAL_MODE_FRONT)
	move_child(heading, 0)
	if get_child_count() > 0:
		fold_button = NodeUtils.get_node_or_add(heading, "FoldButton", Button, NodeUtils.INTERNAL)
		fold_button.icon = icon_open
		fold_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fold_button.flat = true
		fold_button.toggle_mode = true
		fold_button.expand_icon = true
		fold_button.toggled.connect(_fold)
		fold_button.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		fold_button.theme = preload("res://resources/NoFocusColor.tres")

	_refresh_text()
	renamed.connect(_refresh_text)
	label_settings.changed.connect(_refresh_text)

func _refresh_text() -> void:
	heading.name = name
	heading.label_settings = label_settings
	heading._refresh_text()

func _fold(folded: bool) -> void:
	fold_button.icon = icon_closed if folded else icon_open
	get_children().map(func(child): child.visible = not folded)
