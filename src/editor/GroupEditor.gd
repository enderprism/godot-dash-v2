extends PanelContainer
class_name GroupEditor

@export var line_edit: LineEdit
@export var confirm_button: Button
@export var group_container: Container

var selected_objects: Array[Node2D]:
	set(value):
		selected_objects = value
		_populate_group_list(value)
var group_buttons: Dictionary

const NONSHARED_GROUP_COLOR := Color("#8dffcc")
const GROUP_PREFIX := "g_"


func _update_groups(selection: Array[Node2D], group: String, add: bool) -> void:
	if add:
		if group not in group_buttons.keys():
			if group == "":
				return
			selection.map(func(object): object.add_to_group(group, true))
			var group_button := Button.new()
			group_button.text = group.lstrip(GROUP_PREFIX)
			group_button.pressed.connect(_remove_group)
			group_container.add_child(group_button)
			group_buttons[group] = group_button
		elif group_buttons[group].modulate == NONSHARED_GROUP_COLOR:
			selection.map(func(object): object.add_to_group(group, true))
			group_buttons[group].modulate = Color.WHITE
	else:
		selection.map(func(object): object.remove_from_group(group))
		group_buttons.erase(group)


func _on_line_edit_text_submitted(new_text:String) -> void:
	_update_groups(selected_objects, GROUP_PREFIX + new_text, true)
	# TODO "keep focus" doesn't work
	if not Input.is_action_pressed(&"ui_accept_keep_focus"):
		get_viewport().gui_release_focus()
	line_edit.clear()


func _on_button_pressed() -> void:
	_update_groups(selected_objects, GROUP_PREFIX + line_edit.get_text(), true)
	line_edit.clear()


func _remove_group() -> void:
	var selected_group_button := get_viewport().gui_get_focus_owner() as Button
	var group := GROUP_PREFIX + selected_group_button.text
	_update_groups(selected_objects, group, false)
	get_viewport().gui_release_focus()
	selected_group_button.queue_free()


func _populate_group_list(selection: Array[Node2D]) -> void:
	if selection.is_empty():
		return
	var new_groups: Array
	# Groups that all objects are in.
	var shared_groups: Array
	for object in selection:
		if new_groups.is_empty():
			new_groups = object.get_groups() if not object.get_groups().is_empty() else [null]
			shared_groups = object.get_groups()
		elif not object.get_groups().is_empty():
			new_groups = ArrayUtils.union(new_groups, object.get_groups(), TYPE_STRING_NAME, "")
			shared_groups = ArrayUtils.intersect(shared_groups, object.get_groups(), TYPE_STRING_NAME, "")
	new_groups = new_groups.filter(_godot_group_is_trigger_group)
	# Additive pass
	for new_group in new_groups:
		if new_group not in group_buttons.keys() and new_group != null:
			group_buttons[new_group] = Button.new()
			group_buttons[new_group].text = new_group.lstrip(GROUP_PREFIX)
			group_buttons[new_group].pressed.connect(_remove_group)
			group_container.add_child(group_buttons[new_group])
	# Substractive pass
	for old_group in group_buttons.keys():
		if old_group not in new_groups and old_group != null:
			group_buttons[old_group].queue_free()
			group_buttons.erase(old_group)
	# Shared/non-shared groups pass
	for group in group_buttons.keys():
		group_buttons[group].modulate = Color.WHITE if group in shared_groups else NONSHARED_GROUP_COLOR

func _godot_group_is_trigger_group(group: String) -> bool:
	return group.begins_with(GROUP_PREFIX)
