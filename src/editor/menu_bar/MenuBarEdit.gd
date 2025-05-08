extends PopupMenu

@export var edit_handler: EditHandler

func _on_index_pressed(index:int) -> void:
	match index:
		0: # Copy
			edit_handler.copy_selection()
		1: # Paste
			edit_handler.paste_selection()
		2: # Duplicate
			edit_handler.duplicate_selection()
		4: # Select All
			edit_handler.select_all()
		5: # Deselect All
			edit_handler.clear_selection()

