extends Node
class_name TriggerSetup
## Helper class containing boilerplate code
## to set up triggers.

const NONE := 0
const ADD_TARGET_LINK := 1 << 0
const ADD_EASING := 1 << 1

const TRIGGER_UI_DIRECTORY: String = "res://scenes/components/game_components/trigger_ui/"


static func setup(caller: Node, options: int = ADD_EASING):
	# "Group" parent in Godot to avoid moving its TriggerBase instead of it directly
	caller.set_meta("_edit_group_", true)
	#region Avoid re-instancing TriggerBase, TriggerEasing and TargetLink if they already exist
	#region Init TargetLink (some triggers may not need it, if their target is outside the level scene)
	if options & ADD_TARGET_LINK:
		caller.target_link = NodeUtils.get_node_or_add(caller, "TargetLink", load("res://src/TargetLink.gd"))
	#endregion
	#region Init TriggerBase
	caller.base = NodeUtils.get_node_or_add(caller, "TriggerBase", load("res://src/triggers/trigger_components/TriggerBase.gd"))
	#endregion
	#region Init TriggerEasing (a few triggers that are always instant might not need one, e.g. ToggleTrigger and SongTrigger)
	if options & ADD_EASING:
		caller.easing = NodeUtils.get_node_or_add(caller, "TriggerEasing", load("res://src/triggers/trigger_components/TriggerEasing.gd"))
	#endregion
	#region Set children owner to make them show in the scene tree
	NodeUtils.set_child_owner(caller, caller.base)
	if options & ADD_EASING:
		NodeUtils.set_child_owner(caller, caller.easing)
	if options & ADD_TARGET_LINK:
		NodeUtils.set_child_owner(caller, caller.target_link)
	#endregion
	#region Signal connections
	NodeUtils.connect_new(caller.base.body_entered, caller.start)
	if options & ADD_EASING:
		NodeUtils.connect_new(caller.base.body_entered, caller.easing.start)
	if options & ADD_TARGET_LINK:
		NodeUtils.connect_new(caller.base.target_changed, caller.update_target_link)
	#endregion
	#region UI Layout
	var ui_path: String = TRIGGER_UI_DIRECTORY + caller.get_script().get_global_name() + "UI.tscn"
	caller.base.ui_path = ui_path
	#endregion
	if LevelManager.in_editor:
		var editor_selection_collider := preload("res://scenes/components/level_components/EditorSelectionCollider.tscn").instantiate() as EditorSelectionCollider
		editor_selection_collider.type = EditorSelectionCollider.Type.TRIGGER
		editor_selection_collider.id = hash(caller.get_script())
		caller.add_child(editor_selection_collider)
		NodeUtils.set_child_owner(caller, editor_selection_collider)
