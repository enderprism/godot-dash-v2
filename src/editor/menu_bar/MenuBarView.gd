extends PopupMenu

@export var game_scene: Node2D
@export var side_panel: Container
@export var bottom_panel: Container

func _on_index_pressed(index:int) -> void:
	match index:
		0: # Grid
			game_scene.get_node("EditorGridParallax/EditorGrid").visible = not is_item_checked(index)
		1: # Side Panel
			side_panel.visible = not is_item_checked(index)
		2: # Bottom Panel
			bottom_panel.visible = not is_item_checked(index)
	set_item_checked(index, not is_item_checked(index))

