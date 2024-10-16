@tool
extends Node

@export var icons: Array[Texture2D]:
	set(value):
		icons = value

@onready var tab_container := get_parent() as TabContainer

func _refresh_icon_list() -> void:
	for i in range(len(icons)):
		tab_container.set_tab_icon(i, icons[i])
		tab_container.set_tab_icon_max_width(i, 32)
		tab_container.set_tab_title(i, "")

func _on_tab_container_ready() -> void:
	_refresh_icon_list()
