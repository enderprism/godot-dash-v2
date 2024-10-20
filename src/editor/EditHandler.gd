extends Node

signal selection_zone_changed(new_zone: Rect2)

var selection: Array[Node2D]
var object_move_cooldown: float
var placed_objects_collider: Area2D
var editor_mode: TabContainer


func _physics_process(delta: float) -> void:
	if object_move_cooldown > 0:
		object_move_cooldown -= delta
	if editor_mode.get_current_tab_control().name == "Edit":
		_update_selection()
	if not selection.is_empty():
		if Input.is_action_pressed(&"editor_add"):
			selection.map(_add_selection_highlight)
		if Input.is_action_just_pressed(&"editor_deselect"):
			selection.map(func(object): object.get_node("SelectionHighlight").queue_free())
			selection.clear()
			_reset_selection_zone()
		if Input.is_action_just_pressed(&"editor_delete"):
			selection.map(func(object): object.queue_free())
			selection.clear()
			_reset_selection_zone()
		if Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down") and object_move_cooldown <= 0:
			var move_vector: Vector2
			move_vector.x = Input.get_axis(&"ui_left", &"ui_right")
			move_vector.y = Input.get_axis(&"ui_up", &"ui_down")
			print_debug(move_vector)
			selection.map(func(object): object.global_position += move_vector * LevelManager.CELL_SIZE)
			object_move_cooldown = 0.2
	if not Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down"):
		object_move_cooldown = 0.0
	if Input.is_action_just_released(&"editor_add"):
		_reset_selection_zone()


func _update_selection() -> void:
	if Input.is_action_just_pressed(&"editor_add"):
		if not Input.is_action_just_pressed(&"editor_add_swipe") and not Input.is_action_just_pressed(&"editor_selection_remove"):
			selection.map(func(object): object.get_node("SelectionHighlight").queue_free())
			selection.clear()
		_reset_selection_zone(false)
		if placed_objects_collider.has_overlapping_areas() and not (Input.is_action_just_pressed(&"editor_add_swipe") or Input.is_action_just_pressed(&"editor_selection_remove")):
			selection = [placed_objects_collider.get_overlapping_areas()[-1].get_parent()]
	if Input.is_action_pressed(&"editor_selection_remove"):
		_swipe_selection_zone()
		var selection_buffer := Array($SelectionZone.get_overlapping_areas().map(_get_object_parent), TYPE_OBJECT, "Node2D", null)
		selection.filter(func(object): return object not in selection_buffer)
	elif Input.is_action_pressed(&"editor_add"):
		_swipe_selection_zone()
		selection.append_array(Array($SelectionZone.get_overlapping_areas().map(_get_object_parent), TYPE_OBJECT, "Node2D", null))


func _get_object_parent(object: Node) -> Node2D:
	if object.get_parent() is TriggerBase:
		return object.get_parent().get_parent()
	else:
		return object.get_parent()


func _add_selection_highlight(object: Node2D) -> void:
	if not object.has_node("SelectionHighlight"):
		object.add_child(SelectionHighlight.new())


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