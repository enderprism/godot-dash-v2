extends PanelContainer
class_name TriggerEditor

func build_ui(ui_path: String) -> void:
	if not ResourceLoader.exists(ui_path, "PackedScene"):
		printerr("Trigger UI doesn't exist for path: ", ui_path)
		return
	var ui := load(ui_path) as PackedScene
	var free_children := func(object): object.queue_free()
	$MarginContainer.get_children().map(free_children)
	$MarginContainer.add_child(ui.instantiate())
