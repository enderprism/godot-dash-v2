class_name SidePanelManager
extends Node

@export var side_panel: PanelContainer
@export_group("Groups")
@export var group_section: SectionHeading
@export var group_editor: GroupEditor
@export_group("Colors")
@export var base: Property
@export var detail: Property
@export var hsv_shift: SectionHeading

func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	for element in [group_section, base, detail, hsv_shift]:
		element.visible = not selection.is_empty()
	group_editor.selected_objects = selection
