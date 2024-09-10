extends Node
class_name TriggerSetup
## Helper class containing boilerplate code
## to set up triggers.


static func setup(caller: Node, add_target_link: bool, add_easing: bool = true):
	# "Group" parent in Godot to avoid moving its TriggerBase instead of it directly
	caller.set_meta("_edit_group_", true)
	#region Avoid re-instancing TriggerBase, TriggerEasing and TargetLink if they already exist
	#region Init TargetLink (some triggers may not need it, if their target is outside the level scene)
	if add_target_link:
		if not caller.has_node("TargetLink"):
			caller.target_link = load("res://scenes/components/game_components/TargetLink.tscn").instantiate()
			caller.add_child(caller.target_link)
		else:
			caller.target_link = caller.get_node("TargetLink")
	#endregion
	#region Init TriggerBase
	if not caller.has_node("TriggerBase"):
		caller.base = TriggerBase.new()
		caller.base.name = "TriggerBase"
		caller.add_child(caller.base)
	else:
		caller.base = caller.get_node("TriggerBase")
	#endregion
	#region Init TriggerEasing (a few triggers that are always instant might not need one, e.g. ToggleTrigger and SongTrigger)
	if add_easing:
		if not caller.has_node("TriggerEasing"):
			caller.easing = TriggerEasing.new()
			caller.easing.name = "TriggerEasing"
			caller.add_child(caller.easing)
		else:
			caller.easing = caller.get_node("TriggerEasing")
	#endregion
	#endregion
	#region Set children owner to make them show in the scene tree
	set_child_owner(caller, caller.base)
	if add_easing: set_child_owner(caller, caller.easing)
	if add_target_link: set_child_owner(caller, caller.target_link)
	#endregion
	#region Signal connections
	
	if not caller.base.is_connected("body_entered", caller.start):
		caller.base.body_entered.connect(caller.start)
	if not caller.base.is_connected("body_entered", caller.easing.start):
		caller.base.body_entered.connect(caller.easing.start)
	if add_target_link and not caller.base.is_connected("target_changed", caller.update_target_link):
		caller.base.target_changed.connect(caller.update_target_link)
	#endregion
	#region ITC Groups
	if caller.base.target_group != null and not Engine.is_editor_hint() or LevelManager.in_editor:
		var _triggers_on_parent_target_group: String = caller.base.target_group + "-triggers"
		caller.add_to_group(_triggers_on_parent_target_group)
	#endregion

static func set_child_owner(caller: Node, _child: Node) -> void:
	var _owner: Node = caller.get_parent() if caller.get_parent().get_owner() == null else caller.get_parent().get_owner()
	_child.set_owner(_owner)