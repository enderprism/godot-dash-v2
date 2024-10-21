extends Node


const EDITOR_CONFIG_PATH := "user://editor_config.ini"
var editor_config := ConfigFile.new()


func _ready() -> void:
	editor_config.load(EDITOR_CONFIG_PATH)