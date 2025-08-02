class_name SidePanelManager
extends Node

@export var side_panel: PanelContainer
@export var object_name: LineEdit
@export_group("Groups")
@export var group_section: SectionHeading
@export var group_editor: GroupEditor
@export_group("Triggers")
@export var trigger_section: SectionHeading
@export var trigger_editor: TriggerEditor
@export var trigger_properties: Array[BoolProperty]
@export_group("Colors")
@export var color_section: SectionHeading
@export var base: StringProperty
@export var detail: StringProperty
@export var hsv_shift: SectionHeading


func _ready() -> void:
	object_name.text_submitted.connect(update_object_name)
	_on_edit_handler_selection_changed([])


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	object_name.visible = not selection.is_empty()
	if selection.size() == 1:
		object_name.text = selection[0].name
		object_name.editable = true
	elif selection.size() > 1:
		object_name.text = "Multiple objects"
		object_name.editable = false
	#section Groups
	group_section.visible = not selection.is_empty()
	group_editor.selected_objects = selection
	#endsection
	#section Trigger
	trigger_section.visible = TriggerUIHandler.is_selection_trigger_only(selection)
	if not trigger_section.folded:
		trigger_editor.visible = TriggerUIHandler.is_selection_trigger_only(selection) and TriggerUIHandler.is_selection_same_trigger_type(selection)
		for property in trigger_properties:
			property.visible = TriggerUIHandler.is_selection_trigger_only(selection)
	#endsection
	#section Colors
	color_section.visible = not trigger_section.visible
	if not trigger_section.visible and not color_section.folded:
		for element in [base, detail, hsv_shift]:
			element.visible = not selection.is_empty()
	#endsection


func update_object_name(text: String):
	var selection = $"../EditHandler".selection
	if selection.size() == 1:
		selection[0].name = text
	get_viewport().gui_release_focus() # Restore editor keybinds
