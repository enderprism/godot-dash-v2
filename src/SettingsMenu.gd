extends TabContainer

var viewport_size: Vector2


func _ready() -> void:
	get_tree().root.content_scale_size = Config.config.game_resolution
	get_tree().root.content_scale_factor = Config.config.game_scale_factor


func _on_game_resolution_value_changed(new_value: Vector2) -> void:
	viewport_size = $ViewportSizeValue.viewport_size
	get_tree().root.content_scale_size = new_value
	if viewport_size != Vector2.ZERO:
		get_tree().root.content_scale_factor = new_value.y/viewport_size.y
		Config.config.game_scale_factor = get_tree().root.content_scale_factor
		Config.config.save()
