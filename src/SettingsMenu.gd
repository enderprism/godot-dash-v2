extends TabContainer


func _enter_tree() -> void:
	Engine.max_fps = int(Config.config.max_fps)
	DisplayServer.window_set_vsync_mode(Config.config.vsync)
	DisplayServer.window_set_mode(%WindowModePicker.get_item_id(Config.config.window_mode))
	AudioServer.set_bus_layout(load("user://default_bus_layout.tres"))

func _on_max_fps_value_changed(value:float) -> void:
	Engine.max_fps = int(value)


func _on_vsync_value_changed(id: int) -> void:
	DisplayServer.window_set_vsync_mode(id)


func _on_window_mode_value_changed(id: int) -> void:
	DisplayServer.window_set_mode(id)

func _on_game_volume_value_changed(value:float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), linear_to_db(value))
	ResourceSaver.save(AudioServer.generate_bus_layout(), "user://default_bus_layout.tres")


func _on_music_volume_value_changed(value:float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), linear_to_db(value))
	ResourceSaver.save(AudioServer.generate_bus_layout(), "user://default_bus_layout.tres")


func _on_game_sfx_volume_value_changed(value:float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Game SFX"), linear_to_db(value))
	ResourceSaver.save(AudioServer.generate_bus_layout(), "user://default_bus_layout.tres")


func _on_in_level_sfx_volume_value_changed(value:float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"In Level SFX"), linear_to_db(value))
	ResourceSaver.save(AudioServer.generate_bus_layout(), "user://default_bus_layout.tres")


