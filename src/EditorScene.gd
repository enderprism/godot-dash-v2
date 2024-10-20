extends Control

class_name EditorScene

enum EditorAction {
	SWIPE     = 1 << 0,
	ROTATE    = 1 << 1,
	FREE_MOVE = 1 << 2,
	SNAP      = 1 << 3,
}

@onready var level := LevelProps.new()
@onready var placed_objects_collider := $PlacedObjectsCollider as Area2D
@onready var block_palette_button_group := %RegularBlock01.button_group as ButtonGroup

var editor_actions: int
var object_move_cooldown: float

func _ready() -> void:
	if LevelManager.entering_editor:
		LevelManager.entering_editor = false
		var _fade_screen = $FadeScreenLayer/FadeScreen
		_fade_screen.show()
		_fade_screen.modulate = Color("000000ff")
		_fade_screen.fade_out(0.5, Tween.EASE_OUT, Tween.TRANS_EXPO)
		create_tween().tween_property($EditorCamera, "zoom", Vector2.ONE * 0.8, 0.5)\
				.set_ease(Tween.EASE_OUT) \
				.set_trans(Tween.TRANS_EXPO) \
				.from(Vector2.ONE * 0.4)
	
	LevelManager.level_playing = false
	$EditorCamera.enabled = true
	$GameScene/PlayerCamera.enabled = false
	$GameScene/EditorGridParallax/EditorGrid.show()
	$GameScene/EditorGridParallax/EditorGrid.queue_redraw()

	LevelManager.in_editor = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%MenuBar/View.set_item_submenu(0, "PanelVisibility")
	$EditorCamera.zoom_changed.connect($GameScene/EditorGridParallax/EditorGrid.queue_redraw)
	$GameScene/Level.add_child(level)
	set_process_input(false)
	set_process_unhandled_input(true)

func _physics_process(delta: float) -> void:
	placed_objects_collider.global_position = get_local_mouse_position()
	object_move_cooldown -= delta

	if Input.is_action_just_pressed(&"editor_place_mode"):
		%EditorModes.current_tab = 0
	elif Input.is_action_just_pressed(&"editor_edit_mode"):
		%EditorModes.current_tab = 1
	elif Input.is_action_just_pressed(&"editor_selection_filters_mode"):
		%EditorModes.current_tab = 2

	if Input.is_action_just_pressed(&"editor_add") or Input.is_action_just_pressed(&"editor_remove") \
			or Input.is_action_pressed(&"editor_add_swipe") or Input.is_action_pressed(&"editor_remove_swipe") \
			or (editor_actions & EditorAction.SWIPE and (Input.is_action_pressed(&"editor_add") or Input.is_action_pressed(&"editor_remove"))):
		match %EditorModes.get_current_tab_control().name:
			"Place":
				$PlaceHandler.handle_place(block_palette_button_group, placed_objects_collider, level)
			"Edit":
				$EditHandler.handle_edit(placed_objects_collider)
	if not $EditHandler.selection.is_empty():
		if Input.is_action_just_pressed(&"editor_delete"):
			$EditHandler.selection.map(func(object): object.queue_free())
			$EditHandler.selection.clear()
		if Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down") and object_move_cooldown <= 0:
			var move_vector: Vector2
			move_vector.x = Input.get_axis(&"ui_left", &"ui_right")
			move_vector.y = Input.get_axis(&"ui_up", &"ui_down")
			$EditHandler.selection.map(func(object): object.position += Vector2(move_vector.x * LevelManager.CELL_SIZE, move_vector.y * LevelManager.CELL_SIZE))
			object_move_cooldown = 0.2
		elif not Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down"):
			object_move_cooldown = 0.0

func texture_variation_overlapping(type: EditorSelectionCollider.Type, id: int) -> bool:
	if not placed_objects_collider.has_overlapping_areas():
		return false
	if placed_objects_collider.get_overlapping_areas()[-1].get_parent() is Interactable \
			or placed_objects_collider.get_overlapping_areas()[-1].get_parent() is TriggerBase:
		return true
	if placed_objects_collider.get_overlapping_areas()[-1].type == type:
		return placed_objects_collider.get_overlapping_areas()[-1].id == id
	return false


func _on_button_pressed() -> void:
	$GameScene._start_level()
	$EditorCamera.enabled = not $EditorCamera.enabled
	$GameScene/PlayerCamera.enabled = not $GameScene/PlayerCamera.enabled