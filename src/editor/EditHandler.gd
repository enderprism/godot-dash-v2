extends Node

signal selection_zone_changed(new_zone: Rect2)

var selection: Array[Node2D]
var object_move_cooldown: float
var placed_objects_collider: Area2D
var editor_mode: TabContainer
var rotation_lock := false ## Lock variable to ensure 2 rotations aren't happening at the same time.
var selection_index := -1

func _physics_process(delta: float) -> void:
	if object_move_cooldown > 0:
		object_move_cooldown -= delta
	if get_viewport().gui_get_hovered_control() == null:
		if editor_mode.get_current_tab_control().name == "Edit":
			_update_selection()
			get_viewport().gui_release_focus()
		if not selection.is_empty():
			if Input.is_action_just_pressed(&"editor_single_selection_cycle"):
				selection_index -= 1
			if Input.is_action_just_pressed(&"editor_deselect"):
				selection.map(func(object): object.get_node("SelectionHighlight").queue_free())
				selection.clear()
				_reset_selection_zone()
			if Input.is_action_just_pressed(&"editor_delete"):
				selection.map(func(object): object.queue_free())
				selection.clear()
				_reset_selection_zone()
			if Input.is_action_just_pressed(&"editor_duplicate"):
				_duplicate_selection()
				object_move_cooldown = 5
			if Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down") and object_move_cooldown <= 0:
				var move_vector: Vector2
				move_vector.x = Input.get_axis(&"ui_left", &"ui_right")
				move_vector.y = Input.get_axis(&"ui_up", &"ui_down")
				selection.map(func(object): object.global_position += move_vector * LevelManager.CELL_SIZE)
				object_move_cooldown = 0.2
			if not rotation_lock:
				if Input.get_axis(&"editor_rotate_-45", &"editor_rotate_45") and object_move_cooldown <= 0:
					_rotate_selection(Input.get_axis(&"editor_rotate_-45", &"editor_rotate_45") * 45.0)
					object_move_cooldown = 0.2
				if Input.get_axis(&"editor_rotate_-90", &"editor_rotate_90") and object_move_cooldown <= 0:
					_rotate_selection(Input.get_axis(&"editor_rotate_-90", &"editor_rotate_90") * 90.0)
					object_move_cooldown = 0.2
		if not (Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
				or Input.get_axis(&"editor_rotate_-45", &"editor_rotate_45")
				or Input.get_axis(&"editor_rotate_-90", &"editor_rotate_90")):
			object_move_cooldown = 0.0
		if Input.is_action_just_released(&"editor_add"):
			selection.map(_add_selection_highlight)
			_reset_selection_zone()


func _update_selection() -> void:
	if Input.is_action_just_pressed(&"editor_add"):
		if not Input.is_action_just_pressed(&"editor_add_swipe") and not Input.is_action_just_pressed(&"editor_selection_remove") \
				and not Input.is_action_just_pressed(&"editor_single_selection_cycle"):
			selection.map(func(object): object.get_node("SelectionHighlight").queue_free())
			selection.clear()
			selection_index = -1
		_reset_selection_zone(false)
		if placed_objects_collider.has_overlapping_areas() and not (Input.is_action_just_pressed(&"editor_add_swipe") or Input.is_action_just_pressed(&"editor_selection_remove")):
			selection = [placed_objects_collider.get_overlapping_areas()[selection_index%len(placed_objects_collider.get_overlapping_areas())].get_parent()]
	if Input.is_action_pressed(&"editor_selection_remove") or Input.is_action_pressed(&"editor_add"):
		_swipe_selection_zone()
	var selection_buffer := Array($SelectionZone.get_overlapping_areas().map(_get_object_parent), TYPE_OBJECT, "Node2D", null)
	if Input.is_action_just_released(&"editor_selection_remove"):
		ArrayUtils.intersect(selection, selection_buffer, TYPE_OBJECT, "Node2D").map(func(object): object.get_node("SelectionHighlight").queue_free())
		selection = ArrayUtils.difference(selection, selection_buffer, TYPE_OBJECT, "Node2D")
	elif Input.is_action_just_released(&"editor_add") and $SelectionZone/Hitbox.shape.size > Vector2.ONE * 2:
		selection = ArrayUtils.union(selection, selection_buffer, TYPE_OBJECT, "Node2D")


func _get_object_parent(object: Node) -> Node2D:
	if object.get_parent() is TriggerBase:
		return object.get_parent().get_parent()
	else:
		return object.get_parent()


func _add_selection_highlight(object: Node2D) -> void:
	if not object.has_node("SelectionHighlight"):
		var selection_highlight = SelectionHighlight.new()
		object.add_child(selection_highlight)


func _reset_selection_zone(unreachable: bool = true) -> void:
	$SelectionZone.position = Vector2.ONE * INF if unreachable else get_parent().get_local_mouse_position()
	$SelectionZone/Hitbox.shape.size = Vector2.ZERO
	$SelectionZone/Hitbox.position = Vector2.ZERO
	selection_zone_changed.emit(Rect2(Vector2.ZERO, Vector2.ZERO))


func _swipe_selection_zone() -> void:
	var mouse_position := get_parent().get_local_mouse_position() as Vector2
	var hitbox := $SelectionZone/Hitbox as CollisionShape2D
	
	hitbox.shape.size = abs(mouse_position - $SelectionZone.position)
	# Right Down
	if mouse_position.x >= $SelectionZone.position.x and mouse_position.y >= $SelectionZone.position.y:
		hitbox.position = hitbox.shape.size * 0.5
	# Right Up
	elif mouse_position.x >= $SelectionZone.position.x and mouse_position.y < $SelectionZone.position.y:
		hitbox.position.x = hitbox.shape.size.x * 0.5
		hitbox.position.y = -hitbox.shape.size.y * 0.5
	# Left Down
	elif mouse_position.x < $SelectionZone.position.x and mouse_position.y >= $SelectionZone.position.y:
		hitbox.position.x = -hitbox.shape.size.x * 0.5
		hitbox.position.y = hitbox.shape.size.y * 0.5
	# Left Up
	elif mouse_position.x < $SelectionZone.position.x and mouse_position.y < $SelectionZone.position.y:
		hitbox.position = -hitbox.shape.size * 0.5
	
	selection_zone_changed.emit(Rect2($SelectionZone/Hitbox.position - $SelectionZone/Hitbox.shape.size * 0.5, $SelectionZone/Hitbox.shape.size))


func _clone(object: Node) -> Node:
	var packer := PackedScene.new()
	packer.pack(object)
	var clone := packer.instantiate()
	object.get_parent().add_child(clone)
	clone.owner = object.owner
	return clone


func _duplicate_selection() -> void:
	selection.map(func(object): object.modulate = object.get_node("SelectionHighlight").original_modulate)
	selection.map(func(object): object.get_node("SelectionHighlight").queue_free())
	selection = Array(selection.map(_clone), TYPE_OBJECT, "Node2D", null)
	selection.map(_add_selection_highlight)
	selection.map(func(object): object.get_node("SelectionHighlight")._set_duplicate())


func _rotate_selection(angle: float) -> void:
	rotation_lock = true
	var rotation_center_position: Vector2
	var group_parents := selection.filter(func(object): object.has_meta("group_parent"))
	var object_parents := selection.map(func(object): return object.get_parent())
	if not group_parents.is_empty():
		rotation_center_position = group_parents[0].global_position
	else:
		# Take the median of the position of all objects
		var object_positions := selection.duplicate().map(func(object): return object.global_position)
		rotation_center_position = ArrayUtils.transform(object_positions, ArrayUtils.Transformation.MEAN, true)
	var rotation_center = Node2D.new()
	get_parent().add_child(rotation_center)
	rotation_center.global_position = rotation_center_position
	selection.map(func(object): object.reparent(rotation_center))
	rotation_center.rotation_degrees += angle
	for i in len(selection):
		selection[i].reparent(object_parents[i])
	rotation_lock = false


func _on_place_handler_object_deleted(object:Node) -> void:
	selection.erase(object)
