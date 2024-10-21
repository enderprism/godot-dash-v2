extends Node


const EDITOR_CONFIG_PATH := "user://editor.ini"
var editor := ConfigFile.new()


func _ready() -> void:
	editor.load(EDITOR_CONFIG_PATH)