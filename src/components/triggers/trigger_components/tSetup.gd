@tool
extends Node
class_name tSetup
## Helper class containing boilerplate code
## to set up triggers.

func _init(_parent: Node, _add_target_link: bool, _add_easing: bool = true):
	# "Group" parent in Godot to avoid moving its tBase instead of it directly
	_parent.set_meta("_edit_group_", true)
	#region Avoid re-instancing tBase, tEasing and TargetLink if they already exist
	#region Init TargetLink (some triggers may not need it, if their target is outside the level scene)
	if _add_target_link:
		if not _parent.has_node("TargetLink"):
			_parent._target_link = load("res://scenes/components/game_components/GDTargetLink.tscn").instantiate()
			_parent.add_child(_parent._target_link)
		else:
			_parent._target_link = _parent.get_node("TargetLink")
	#endregion
	#region Init tBase
	if not _parent.has_node("tBase"):
		_parent._base = tBase.new()
		_parent._base.name = "tBase"
		_parent.add_child(_parent._base)
	else:
		_parent._base = _parent.get_node("tBase")
	#endregion
	#region Init tEasing (a few triggers that are always instant might not need one, e.g. tToggle and tSong)
	if _add_easing:
		if not _parent.has_node("tEasing"):
			_parent._easing = tEasing.new()
			_parent._easing.name = "tEasing"
			_parent.add_child(_parent._easing)
		else:
			_parent._easing = _parent.get_node("tEasing")
	#endregion
	#endregion
	#region Set children owner to make them show in the scene tree
	_set_child_owner(_parent, _parent._base)
	if _add_easing: _set_child_owner(_parent, _parent._easing)
	if _add_target_link: _set_child_owner(_parent, _parent._target_link)
	#endregion
	#region Signal connections
	if not _parent._base.is_connected("body_entered", _parent._start):
		_parent._base.body_entered.connect(_parent._start)
	if not _parent._base.is_connected("body_entered", _parent._easing._start):
		_parent._base.body_entered.connect(_parent._easing._start)
	if _add_target_link and not _parent._base.is_connected("target_changed", _parent._update_target_link):
		_parent._base.target_changed.connect(_parent._update_target_link)
	#endregion

func _set_child_owner(_parent, _child) -> void:
	var _owner: Node = _parent.get_parent() if _parent.get_parent().get_owner() == null else _parent.get_parent().get_owner()
	_child.set_owner(_owner)