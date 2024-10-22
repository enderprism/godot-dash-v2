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
		caller.target_link = get_node_or_add(caller, "TargetLink", load("res://src/TargetLink.gd"))
	#endregion
	#region Init TriggerBase
	caller.base = get_node_or_add(caller, "TriggerBase", load("res://src/triggers/trigger_components/TriggerBase.gd"))
	#endregion
	#region Init TriggerEasing (a few triggers that are always instant might not need one, e.g. ToggleTrigger and SongTrigger)
	if add_easing:
		caller.easing = get_node_or_add(caller, "TriggerEasing", load("res://src/triggers/trigger_components/TriggerEasing.gd"))
	#endregion
	#region Set children owner to make them show in the scene tree
	set_child_owner(caller, caller.base)
	if add_easing: set_child_owner(caller, caller.easing)
	if add_target_link: set_child_owner(caller, caller.target_link)
	#endregion
	#region Signal connections
	connect_new(caller.base.body_entered, caller.start)
	connect_new(caller.base.body_entered, caller.easing.start)
	if add_target_link:
		connect_new(caller.base.target_changed, caller.update_target_link)
	#endregion
	if LevelManager.in_editor:
		var editor_selection_collider := preload("res://scenes/components/level_components/EditorSelectionCollider.tscn").instantiate() as EditorSelectionCollider
		editor_selection_collider.type = EditorSelectionCollider.Type.TRIGGER
		editor_selection_collider.id = hash(caller.get_script())
		caller.add_child(editor_selection_collider)
		set_child_owner(caller, editor_selection_collider)

static func set_child_owner(caller: Node, child: Node) -> void:
	var _owner: Node = caller.get_parent() if caller.get_parent().get_owner() == null else caller.get_parent().get_owner()
	child.set_owner(_owner)

static func get_node_or_add(caller: Node, path: NodePath, script, internal: bool = false) -> Node:
	var node := caller.get_node_or_null(path)
	if node == null:
		node = script.new()
		node.name = str(path)
		caller.add_child(node, internal)
		set_child_owner(caller, node)
	return node

static func connect_new(_signal: Signal, callable: Callable) -> void:
	if not _signal.is_connected(callable):
		_signal.connect(callable)