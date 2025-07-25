extends Control
class_name LevelSettings

var saveloads: Array

func _ready() -> void:
	$"TabContainer/Level Settings/VBoxContainer".custom_minimum_size.y = $"TabContainer/Level Settings/VBoxContainer".size.y
	saveloads = NodeUtils.get_children_of_type(self, PropertySaveLoad, true)
	var refresh_saveloads := func(saveload: PropertySaveLoad):
		saveload.property_owner = LevelManager.current_level
		saveload.load_value()
	saveloads.map.call_deferred(refresh_saveloads)
	%"Song Path".load_root = "created_levels/songs"
	%"Song Path".import_to = "user://created_levels/songs/"


func _on_menu_bar_handler_level_loaded(level: LevelProps) -> void:
	var refresh_saveloads := func(saveload: PropertySaveLoad):
		saveload.property_owner = level
		saveload.load_value()
	saveloads.map.call_deferred(refresh_saveloads)


func _on_close_pressed() -> void:
	LevelManager.shortcut_blocker = null
	hide()

