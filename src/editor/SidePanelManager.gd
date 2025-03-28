class_name SidePanelManager
extends Node

@export var side_panel: PanelContainer
@export_group("Groups")
@export var group_section: SectionHeading
@export var group_editor: GroupEditor
@export_group("Triggers")
@export var trigger_section: SectionHeading
@export var trigger_editor: TriggerEditor
@export var trigger_properties: Array[Property]
@export_group("Colors")
@export var color_section: SectionHeading
@export var base: Property
@export var detail: Property
@export var hsv_shift: SectionHeading


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	#section Groups
	group_section.visible = not selection.is_empty()
	group_editor.selected_objects = selection
	#endsection
	#section Trigger
	trigger_section.visible = TriggerUIHandler.is_selection_trigger_only(selection)
	if not trigger_section.folded:
		trigger_editor.visible = TriggerUIHandler.is_selection_trigger_only(selection) and len(selection) == 1
		for property in trigger_properties:
			property.visible = TriggerUIHandler.is_selection_trigger_only(selection)
	#endsection
	#section Colors
	color_section.visible = not trigger_section.visible
	if not trigger_section.visible and not color_section.folded:
		for element in [base, detail, hsv_shift]:
			element.visible = not selection.is_empty()
	#endsection
