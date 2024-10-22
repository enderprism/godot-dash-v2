extends TabContainer


func _ready() -> void:
	Engine.max_fps = int(Config.config.max_fps)
	DisplayServer.window_set_vsync_mode(Config.config.vsync)
	DisplayServer.window_set_mode(%WindowModePicker.get_item_id(Config.config.window_mode))

func _on_max_fps_value_changed(value:float) -> void:
	Engine.max_fps = int(value)


func _on_vsync_value_changed(id: int) -> void:
	DisplayServer.window_set_vsync_mode(id)


func _on_window_mode_value_changed(id: int) -> void:
	DisplayServer.window_set_mode(id)