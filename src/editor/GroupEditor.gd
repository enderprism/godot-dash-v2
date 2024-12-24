extends PanelContainer
class_name GroupEditor

@export var line_edit: LineEdit
@export var confirm_button: Button
@export var group_container: Container

var selected_objects: Array[Node2D]:
	set(value):
		selected_objects = value


func _update_groups(selection: Array[Node2D], group: String, add: bool) -> void:
	if add:
		selection.map(func(object): object.add_to_group(group, true))
		var group_button := Button.new()
		group_button.text = group
		group_button.pressed.connect(_remove_group)
		group_container.add_child(group_button)
	else:
		selection.map(func(object): object.remove_from_group(group))


func _on_line_edit_text_submitted(new_text:String) -> void:
	_update_groups(selected_objects, new_text, true)
	# TODO "keep focus" doesn't work
	if not Input.is_action_pressed(&"ui_accept_keep_focus"):
		get_viewport().gui_release_focus()
	line_edit.clear()


func _on_button_pressed() -> void:
	_update_groups(selected_objects, line_edit.get_text(), true)
	get_viewport().gui_release_focus()
	line_edit.clear()

func _remove_group() -> void:
	var selected_group_button := get_viewport().gui_get_focus_owner() as Button
	var group := selected_group_button.text
	_update_groups(selected_objects, group, false)
	get_viewport().gui_release_focus()
	selected_group_button.queue_free()
