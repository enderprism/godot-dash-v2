extends Node

signal object_deleted(object: Node)

func handle_place(block_palette_button_group: ButtonGroup, placed_objects_collider: Area2D, level: LevelProps) -> void:
	if get_viewport().gui_get_hovered_control() == null:
		# Handle object placement
		var pressed_button := block_palette_button_group.get_pressed_button()
		var block_palette_ref: BlockPaletteRef
		if pressed_button != null:
			block_palette_ref = pressed_button.get_node_or_null("BlockPaletteRef") as BlockPaletteRef
		if block_palette_ref != null and not texture_variation_overlapping(placed_objects_collider, block_palette_ref.type, block_palette_ref.id) \
				and Input.is_action_pressed(&"editor_add"):
			if pressed_button != null:
				var object: Node2D
				if block_palette_ref.type == EditorSelectionCollider.Type.TRIGGER:
					object = block_palette_ref.trigger_script.new()
				else:
					object = block_palette_ref.object.instantiate()
				if pressed_button.has_node("BlockPaletteTextureSwap"):
					var block_palette_texture_swap := pressed_button.get_node("BlockPaletteTextureSwap") as BlockPaletteTextureSwap
					var texture_owner: NodePath = block_palette_texture_swap.texture_owner
					var texture_override: Texture = block_palette_texture_swap.texture_override
					object.get_node(block_palette_texture_swap.texture_owner).texture = texture_override
					object.get_node("EditorSelectionCollider").id = block_palette_ref.id
				object.position = (level.get_local_mouse_position() + Vector2(0, 64)).snapped(Vector2.ONE*128) - Vector2(0, 64)
				level.add_child(object)
				object.owner = level
		# Handle object deletion
		elif Input.is_action_pressed(&"editor_remove") and placed_objects_collider.has_overlapping_areas():
			if len(placed_objects_collider.get_overlapping_areas()) > 0:
				object_deleted.emit(placed_objects_collider.get_overlapping_areas()[-1])
				placed_objects_collider.get_overlapping_areas()[-1].get_parent().queue_free()

func texture_variation_overlapping(placed_objects_collider: Area2D, type: EditorSelectionCollider.Type, id: int) -> bool:
	if not placed_objects_collider.has_overlapping_areas():
		return false
	if placed_objects_collider.get_overlapping_areas()[-1].get_parent() is Interactable \
			or placed_objects_collider.get_overlapping_areas()[-1].get_parent() is TriggerBase:
		return true
	if placed_objects_collider.get_overlapping_areas()[-1].type == type:
		return placed_objects_collider.get_overlapping_areas()[-1].id == id
	return false