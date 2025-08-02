extends Node

signal object_deleted(object: Node)

@export var game_scene: Node2D
@export var editor_viewport: Control
@export var edit_handler: EditHandler

var placed_object_rotation_degrees: float
var previous_pressed_button: BaseButton ## Used to detect if the block palette button changed, to reset the placed object rotation.


func handle_place(block_palette_button_group: ButtonGroup, placed_objects_collider: Area2D, level: LevelProps) -> void:
	if get_viewport().gui_get_hovered_control() == editor_viewport:
		# Handle object placement
		var pressed_button := block_palette_button_group.get_pressed_button()
		if previous_pressed_button != pressed_button:
			placed_object_rotation_degrees = 0.0
		previous_pressed_button = pressed_button
		var block_palette_ref: BlockPaletteRef
		if pressed_button != null:
			block_palette_ref = NodeUtils.get_child_of_type(pressed_button, BlockPaletteRef) as BlockPaletteRef
		if block_palette_ref != null and not texture_variation_overlapping(placed_objects_collider, block_palette_ref.type, block_palette_ref.id) \
				and Input.is_action_pressed(&"editor_add"):
			if pressed_button != null:
				# Create object
				var object: Node2D
				if block_palette_ref.type == EditorSelectionCollider.Type.TRIGGER:
					object = block_palette_ref.trigger_script.new()
					object.name = block_palette_ref.trigger_script.get_global_name()
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
				NodeUtils.change_owner_recursive(object, level)
				object.scene_file_path = ""
				var to_be_colored: Array
				to_be_colored.append(object.get_node("Base") if object.has_node("Base") else object)
				if object.has_node("Detail"):
					to_be_colored.append(object.get_node("Detail"))
				for to_be_colored_object in to_be_colored:
					var hsv_watcher := HSVWatcher.new()
					hsv_watcher.name = "HSVWatcher"
					to_be_colored_object.add_child(hsv_watcher)
					hsv_watcher.set_owner(LevelManager.current_level)
				object.rotation_degrees = placed_object_rotation_degrees

				# Version history
				var add_object := func(_object: Node):
					if _object.is_in_group("deleted"):
						_object.remove_from_group("deleted")
					_object.show()
					_object.process_mode = Node.PROCESS_MODE_INHERIT
				var remove_object := func(_object: Node):
					_object.hide()
					_object.process_mode = Node.PROCESS_MODE_DISABLED
					_object.add_to_group("deleted")
				level.version_history.create_action("Place object " + object.name)
				level.version_history.add_do_method(add_object.bind(object))
				level.version_history.add_do_reference(object)
				level.version_history.add_undo_method(remove_object.bind(object))
				level.version_history.commit_action()
	
				# Change selection
				edit_handler.clear_selection()
				edit_handler.selection.append(object)
				edit_handler.selection.map(EditHandler.add_selection_highlight)
				edit_handler.selection_changed.emit(edit_handler.selection)
		# Handle object deletion
		elif Input.is_action_pressed(&"editor_remove") and placed_objects_collider.has_overlapping_areas():
			placed_object_rotation_degrees = 0.0
			if len(placed_objects_collider.get_overlapping_areas()) > 0 and placed_objects_collider.get_overlapping_areas()[-1].get_parent() is not LevelProps:
				var overlapping_areas := placed_objects_collider.get_overlapping_areas()
				object_deleted.emit(overlapping_areas[-1])
				get_area(overlapping_areas[-1]).queue_free()


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


func _on_edit_handler_rotated_object_degrees(rotation_degrees:float) -> void:
	if rotation_degrees == 0.0:
		placed_object_rotation_degrees = 0.0
	else:
		placed_object_rotation_degrees += rotation_degrees

