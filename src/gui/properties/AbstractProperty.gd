extends BoxContainer
class_name AbstractProperty


func reset() -> void:
	pass

func refresh() -> void:
	pass

func set_input_state(enabled: bool) -> void:
	pass


func submitted_release_focus(_new_value):
	get_viewport().gui_release_focus()

func unedit_release_focus(toggled_on):
	if not toggled_on:
		get_viewport().gui_release_focus()
