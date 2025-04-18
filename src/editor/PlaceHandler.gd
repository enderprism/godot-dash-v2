extends Node

signal object_deleted(object: Node)

@export var game_scene: Node2D
@export var editor_viewport: Control

func handle_place(block_palette_button_group: ButtonGroup, placed_objects_collider: Area2D, level: LevelProps) -> void:
	if get_viewport().gui_get_hovered_control() == editor_viewport:
		# Handle object placement
		var pressed_button := block_palette_button_group.get_pressed_button()
		var block_palette_ref: BlockPaletteRef
		if pressed_button != null:
			block_palette_ref = NodeUtils.get_child_of_type(pressed_button, BlockPaletteRef) as BlockPaletteRef
		if block_palette_ref != null and not texture_variation_overlapping(placed_objects_collider, block_palette_ref.type, block_palette_ref.id) \
				and Input.is_action_pressed(&"editor_add"):
			if pressed_button != null:
				var object: Node2D
				if block_palette_ref.type == EditorSelectionCollider.Type.TRIGGER:
					object = block_palette_ref.trigger_script.new()
				else:
					object = block_palette_ref.object.instantiate()
				if pressed_button.has_meta("texture_override"):
					var override = pressed_button.get_meta("texture_override") as TextureOverride
					object.get_node("Base").texture = override.base
					if override.detail != null:
						object.get_node("Detail").texture = override.detail
					object.name = override.name
					object.get_node("EditorSelectionCollider").id = block_palette_ref.id
				var editor_grid := game_scene.get_node("%EditorGrid") as EditorGrid
				var grid_offset_to_level_origin := Vector2(0, 64)
				object.position = (level.get_local_mouse_position() + grid_offset_to_level_origin).snapped(editor_grid.cell_size) - grid_offset_to_level_origin
				level.add_child(object)
				change_owner(object, level)
				object.scene_file_path = ""
				var hsv_watcher := HSVWatcher.new()
				hsv_watcher.name = "HSVWatcher"
				object.add_child(hsv_watcher)
				hsv_watcher.set_owner(LevelManager.editor_edited_level)
		# Handle object deletion
		elif Input.is_action_pressed(&"editor_remove") and placed_objects_collider.has_overlapping_areas():
			if len(placed_objects_collider.get_overlapping_areas()) > 0 and placed_objects_collider.get_overlapping_areas()[-1].get_parent() is not LevelProps:
				var overlapping_areas := placed_objects_collider.get_overlapping_areas()
				object_deleted.emit(overlapping_areas[-1])
				get_area(overlapping_areas[-1]).queue_free()


func change_owner(object: Node, level: LevelProps):
	object.owner = level
	if object.get_child_count() > 0:
		object.get_children().map(change_owner.bind(level))


func get_area(area: Area2D) -> Node:
	return area if area is Interactable else area.get_parent()


func texture_variation_overlapping(placed_objects_collider: Area2D, type: EditorSelectionCollider.Type, id: int) -> bool:
	if not placed_objects_collider.has_overlapping_areas():
		return false
	var overlapping_areas := placed_objects_collider.get_overlapping_areas()
	var is_interactable_or_trigger_base := func(area_parent): return area_parent is Interactable or area_parent is TriggerBase
	if not overlapping_areas.map(get_area).filter(is_interactable_or_trigger_base).is_empty():
		return true
	if placed_objects_collider.get_overlapping_areas()[-1].type == type:
		return placed_objects_collider.get_overlapping_areas()[-1].id == id
	return false
