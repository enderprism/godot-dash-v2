class_name SidePanelManager
extends Node

@export var side_panel: PanelContainer
@export_group("Groups")
@export var group_section: SectionHeading
@export var group_editor: GroupEditor


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	group_section.visible = not selection.is_empty()
	group_editor.selected_objects = selection
