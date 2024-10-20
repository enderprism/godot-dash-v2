extends Node

var selection: Array[Node2D]

func handle_edit(placed_objects_collider: Area2D) -> void:
	selection = _update_selection(selection, placed_objects_collider)
	# print_debug("clicked ", selection)
	# TODO: shift+left click → select area, shift+right click → deselect area

func _update_selection(selection: Array[Node2D], placed_objects_collider: Area2D) -> Array[Node2D]:
	if Input.is_action_just_pressed(&"editor_add"):
		$SelectionZone.position = get_parent().get_local_mouse_position()
		$SelectionZone/Hitbox.shape.size = Vector2.ONE
		$SelectionZone/Hitbox.position = Vector2.ZERO
		if placed_objects_collider.has_overlapping_areas():
			return [placed_objects_collider.get_overlapping_areas()[-1].get_parent()]
		else:
			return []
	elif Input.is_action_pressed(&"editor_add_swipe"):
		$SelectionZone/Hitbox.shape.size = get_parent().get_local_mouse_position() - $SelectionZone.position
		$SelectionZone/Hitbox.position = $SelectionZone/Hitbox.shape.size * 0.5
		return Array($SelectionZone.get_overlapping_areas().map(func(object): return object.get_parent()), TYPE_OBJECT, "Node2D", null)
	# elif Input.is_action_just_released(
	else:
		return []