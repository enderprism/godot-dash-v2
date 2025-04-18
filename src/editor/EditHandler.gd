extends Node
class_name EditHandler

signal selection_zone_changed(new_zone: Rect2)
signal selection_changed(selection: Array[Node2D])
signal clipboard_changed(clipboard: Array[Node2D])

@export var editor_viewport: Control

var level: LevelProps
var selection: Array[Node2D]
var clipboard: Array[Node2D]
var clipboard_camera_position: Vector2
var object_move_cooldown: float
var placed_objects_collider: Area2D
var editor_mode: TabContainer
var rotation_lock := false ## Lock variable to ensure 2 rotations aren't happening at the same time.
var selection_index := 0
var cursor_position_snapped: Vector2
var previous_cursor_position_snapped: Vector2
var selection_pivot := Vector2.INF

func _ready() -> void:
	_reset_selection_zone(true)
	selection_changed.connect(_reset_selection_pivot)
	var update_global_clipboard := func(new_clipboard): LevelManager.editor_clipboard = new_clipboard
	clipboard_changed.connect(update_global_clipboard)

func _physics_process(delta: float) -> void:
	if LevelManager.level_playing:
		return
	if object_move_cooldown > 0:
		object_move_cooldown -= delta
	cursor_position_snapped = level.get_local_mouse_position().snapped(Vector2.ONE*128)
	if cursor_position_snapped != previous_cursor_position_snapped:
		selection_index = 0
	var is_already_swiping_selection: bool = $SelectionZone/Hitbox.shape.size != Vector2.ZERO
	if is_already_swiping_selection or get_viewport().gui_get_hovered_control() == editor_viewport:
		if editor_mode.get_current_tab_control().name == "Edit":
			_update_selection()
		if not selection.is_empty():
			if Input.is_action_just_pressed(&"editor_single_selection_cycle"):
				selection_index -= 1
			if Input.is_action_just_pressed(&"editor_deselect"):
				selection.map(remove_selection_highlight)
				selection.clear()
				_reset_selection_zone()
			if Input.is_action_just_pressed(&"editor_delete"):
				selection.map(func(object): object.queue_free())
				selection.clear()
				_reset_selection_zone()
				selection_changed.emit(selection)
			if Input.is_action_just_pressed(&"editor_duplicate"):
				_duplicate_selection()
				object_move_cooldown = 5
			if Input.is_action_just_pressed(&"ui_copy"):
				_copy_selection()
			if Input.is_action_just_pressed(&"ui_paste"):
				_paste_selection()
				object_move_cooldown = 5
			if Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down") and object_move_cooldown <= 0:
				var move_vector: Vector2
				move_vector.x = Input.get_axis(&"ui_left", &"ui_right")
				move_vector.y = Input.get_axis(&"ui_up", &"ui_down")
				var move_multiplier := 1.0
				if Input.is_key_pressed(KEY_SHIFT):
					move_multiplier = 0.5
				selection.map(func(object): object.global_position += move_vector * LevelManager.CELL_SIZE * move_multiplier)
				object_move_cooldown = 0.2
			if not rotation_lock:
				if Input.get_axis(&"editor_rotate_-45", &"editor_rotate_45") and object_move_cooldown <= 0:
					_rotate_selection(Input.get_axis(&"editor_rotate_-45", &"editor_rotate_45") * 45.0)
					object_move_cooldown = 0.2
				if Input.get_axis(&"editor_rotate_-90", &"editor_rotate_90") and object_move_cooldown <= 0:
					_rotate_selection(Input.get_axis(&"editor_rotate_-90", &"editor_rotate_90") * 90.0)
					object_move_cooldown = 0.2
			if Input.is_action_just_pressed(&"editor_flip_h"):
				_flip_selection(Vector2.AXIS_X)
			if Input.is_action_just_pressed(&"editor_flip_v"):
				_flip_selection(Vector2.AXIS_Y)
		if not (Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
				or Input.get_axis(&"editor_rotate_-45", &"editor_rotate_45")
				or Input.get_axis(&"editor_rotate_-90", &"editor_rotate_90")):
			object_move_cooldown = 0.0
		if Input.is_action_just_released(&"editor_add"):
			selection.map(add_selection_highlight)
			_reset_selection_zone()
	previous_cursor_position_snapped = cursor_position_snapped


func _update_selection() -> void:
	if get_viewport().gui_get_hovered_control() == editor_viewport and Input.is_action_just_pressed(&"editor_add"):
		if not Input.is_action_just_pressed(&"editor_add_swipe") and not Input.is_action_just_pressed(&"editor_selection_remove") \
				and not Input.is_action_just_pressed(&"editor_single_selection_cycle"):
			for object in selection:
				if object.has_node("HSVWatcher"):
					object = object.get_node("HSVWatcher")
				remove_selection_highlight(object)
			selection.clear()
			selection_index += 1
			selection_changed.emit(selection)
		_reset_selection_zone(false)
		if placed_objects_collider.has_overlapping_areas() and not (Input.is_action_just_pressed(&"editor_add_swipe") or Input.is_action_just_pressed(&"editor_selection_remove")):
			selection = [
				_get_object_parent(
						placed_objects_collider.get_overlapping_areas()[
							selection_index%len(placed_objects_collider.get_overlapping_areas())
					]
				)
			]
			selection_changed.emit(selection)
	if Input.is_action_pressed(&"editor_selection_remove") or Input.is_action_pressed(&"editor_add"):
		_swipe_selection_zone()
	var selection_buffer := Array($SelectionZone.get_overlapping_areas().map(_get_object_parent), TYPE_OBJECT, "Node2D", null)
	if Input.is_action_just_released(&"editor_selection_remove"):
		ArrayUtils.intersect(selection, selection_buffer, TYPE_OBJECT, "Node2D").map(remove_selection_highlight)
		selection = ArrayUtils.difference(selection, selection_buffer, TYPE_OBJECT, "Node2D")
		selection_changed.emit(selection)
	elif (Input.is_action_just_released(&"editor_add") and $SelectionZone/Hitbox.shape.size > Vector2.ONE * 2) or Input.is_action_just_released(&"editor_add_swipe"):
		selection = ArrayUtils.union(selection, selection_buffer, TYPE_OBJECT, "Node2D")
		selection_changed.emit(selection)
	selection.erase(level)


func _get_object_parent(object: Node) -> Node2D:
	if object.get_parent() is TriggerBase:
		return object.get_parent().get_parent()
	elif object is EditorSelectionCollider:
		return object.get_parent()
	else:
		return object


static func add_selection_highlight(object: Node2D) -> void:
	if object.has_node("HSVWatcher"):
		object = object.get_node("HSVWatcher")
	if not object.has_node("SelectionHighlight"):
		var selection_highlight = SelectionHighlight.new()
		object.add_child(selection_highlight)


static func remove_selection_highlight(object: Node2D) -> void:
	if object.has_node("HSVWatcher"):
		object = object.get_node("HSVWatcher")
	if not object.has_node("SelectionHighlight"):
		return
	object.modulate = object.get_node("SelectionHighlight").modulate
	if object is HSVWatcher:
		object.get_parent().modulate = object.modulate
	object.get_node("SelectionHighlight").queue_free()


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
	remove_selection_highlight(object)
	NodeUtils.change_owner_recursive(object, object)
	var packer := PackedScene.new()
	packer.pack(object)
	var clone := packer.instantiate()
	object.get_parent().add_child(clone)
	clone.owner = object.owner
	add_selection_highlight(clone)
	NodeUtils.change_owner_recursive(object, level)
	NodeUtils.change_owner_recursive(clone, level)
	return clone


func _duplicate_selection() -> void:
	selection = Array(selection.map(_clone), TYPE_OBJECT, "Node2D", null)
	for object in selection:
		if object.has_node("HSVWatcher"):
			object = object.get_node("HSVWatcher")
		object.get_node("SelectionHighlight")._set_duplicate()
	selection_changed.emit(selection)


func _copy_selection() -> void:
	clipboard = selection.duplicate()
	clipboard_camera_position = get_viewport().get_camera_2d().get_screen_center_position()
	clipboard_changed.emit(clipboard)
	Toasts.new_toast("Selection copied!")


func _paste_selection() -> void:
	selection.map(remove_selection_highlight)
	selection = clipboard.duplicate()
	selection = Array(selection.map(_clone), TYPE_OBJECT, "Node2D", null)
	selection_changed.emit(selection)
	var move_objects_to_new_screen_center = func(object):
		object.global_position += (get_viewport().get_camera_2d().get_screen_center_position() - clipboard_camera_position).snappedf(LevelManager.CELL_SIZE)
	selection.map(move_objects_to_new_screen_center)


func _rotate_selection(angle: float) -> void:
	if selection.is_empty():
		return
	rotation_lock = true
	_update_pivot()
	for object in selection:
		object.global_rotation_degrees += angle
		var position_relative_to_pivot: Vector2 = object.global_position - selection_pivot
		var position_delta := position_relative_to_pivot.rotated(deg_to_rad(angle)) - position_relative_to_pivot
		object.global_position += position_delta
	rotation_lock = false


func _update_pivot() -> void:
	if selection.is_empty():
		return
	var group_parents := selection.filter(func(object): object.has_meta("group_parent"))
	if selection_pivot == Vector2.INF:
		if not group_parents.is_empty():
			selection_pivot = group_parents[0].global_position
		else:
			# Take the mean of the position of all objects
			var object_positions := selection.duplicate().map(func(object): return object.global_position)
			selection_pivot = ArrayUtils.transform(object_positions, ArrayUtils.Transformation.MEAN, true)


func _flip_selection(axis: int):
	if selection.is_empty():
		return
	_update_pivot()
	match axis:
		Vector2.AXIS_X:
			for object in selection:
				object.scale.x *= -1
				var position_relative_to_pivot: Vector2 = object.global_position - selection_pivot
				var x_delta := position_relative_to_pivot.x * -1 - position_relative_to_pivot.x
				object.global_position.x += x_delta
		Vector2.AXIS_Y:
			for object in selection:
				object.scale.y *= -1
				var position_relative_to_pivot: Vector2 = object.global_position - selection_pivot
				var y_delta := position_relative_to_pivot.y * -1 - position_relative_to_pivot.y
				object.global_position.y += y_delta



func _on_place_handler_object_deleted(object:Node) -> void:
	if object in selection:
		selection.erase(object)
		selection_changed.emit(selection)


func _on_move_controls_direction_pressed(direction: Vector2, step: float) -> void:
	if selection.is_empty():
		return
	selection.map(func(object): object.position += LevelManager.CELL_SIZE * direction * step)


func _reset_selection_pivot(_selection: Array[Node2D]) -> void:
	selection_pivot = Vector2.INF


func _on_rotate_left_90_pressed() -> void:
	_rotate_selection(-90)


func _on_rotate_right_90_pressed() -> void:
	_rotate_selection(90)


func _on_rotate_left_45_pressed() -> void:
	_rotate_selection(-45)


func _on_rotate_right_45_pressed() -> void:
	_rotate_selection(45)


func _on_flip_h_pressed() -> void:
	_flip_selection(Vector2.AXIS_X)


func _on_flip_v_pressed() -> void:
	_flip_selection(Vector2.AXIS_Y)

