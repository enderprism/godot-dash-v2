extends CanvasLayer

var menu_tween: Tween


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and $SettingsContainer.position.y == 0:
		menu_tween = create_tween()
		menu_tween.tween_property($SettingsContainer, "position:y", -$SettingsContainer.get_viewport_rect().size.y, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)


func _on_settings_pressed() -> void:
	if $SettingsContainer.position.y == -$SettingsContainer.get_viewport_rect().size.y:
		menu_tween = create_tween()
		menu_tween.tween_property($SettingsContainer, "position:y", 0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
