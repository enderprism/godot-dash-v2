class_name SidePanelManager
extends Node

@export var side_panel: PanelContainer
@export var object_name: LineEdit
@export_group("Groups")
@export var group_section: SectionHeading
@export var group_editor: GroupEditor
@export_group("Interactables")
@export var interactable_section: SectionHeading
@export var trigger_editor: TriggerEditor
@export var interactable_editor: InteractableEditor
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
	interactable_section.visible = TriggerUIHandler.is_selection_interactable_only(selection)
	if not interactable_section.folded:
		trigger_editor.visible = TriggerUIHandler.is_selection_trigger_only(selection) and TriggerUIHandler.is_selection_same_interactable_type(selection)
		interactable_editor.visible = TriggerUIHandler.is_selection_interactable_only(selection) \
				and TriggerUIHandler.is_selection_same_interactable_type(selection) \
				and not TriggerUIHandler.is_selection_trigger_only(selection)
		for property in trigger_properties:
			property.visible = TriggerUIHandler.is_selection_trigger_only(selection) if "triggered" in property.name else interactable_section.visible
	#endsection
	#section Colors
	if not color_section.folded:
		for element in [base, detail, hsv_shift]:
			element.visible = not selection.is_empty()
	#endsection


func update_object_name(text: String):
	var selection = $"../EditHandler".selection
	if selection.size() == 1:
		selection[0].name = text
	get_viewport().gui_release_focus() # Restore editor keybinds
