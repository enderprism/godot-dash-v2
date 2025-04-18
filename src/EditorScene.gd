extends Control

class_name EditorScene

enum EditorAction {
	SWIPE     = 1 << 0,
	ROTATE    = 1 << 1,
	FREE_MOVE = 1 << 2,
	SNAP      = 1 << 3,
}

@export var block_palette_button_group: ButtonGroup

@onready var level := LevelProps.new()
@onready var placed_objects_collider := $PlacedObjectsCollider as Area2D

var editor_actions: int

func _ready() -> void:
	if LevelManager.editor_level_backup.can_instantiate():
		$GameScene/Level.add_child(LevelManager.editor_level_backup.instantiate())
		level = $GameScene/Level.get_child(0)
	elif $GameScene/Level.get_child(0) == null:
		$GameScene/Level.add_child(level)

	if SceneTransition.from_main():
		SceneTransition.previous = SceneTransition.Scene.EDITOR
		var _fade_screen = $FadeScreenLayer/FadeScreen
		_fade_screen.show()
		_fade_screen.modulate = Color("000000ff")
		_fade_screen.fade_out(0.5, Tween.EASE_OUT, Tween.TRANS_SINE)
		create_tween().tween_property($EditorCamera, "zoom", Vector2.ONE * 0.8, 0.5)\
				.set_ease(Tween.EASE_OUT) \
				.set_trans(Tween.TRANS_EXPO) \
				.from(Vector2.ONE * 0.4)
	
	LevelManager.level_playing = false
	$EditorCamera.enabled = true
	%EditorModes.show()
	%SidePanel.show()
	$GameScene/Player.process_mode = Node.PROCESS_MODE_DISABLED
	$GameScene/PlayerCamera.enabled = false
	$GameScene/EditorGridParallax/EditorGrid.show()
	$GameScene/EditorGridParallax/EditorGrid.queue_redraw()
	$GameScene/PauseMenuLayer/PauseMenu.leave.connect(_on_leave_pressed)

	LevelManager.in_editor = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%MenuBar/View.set_item_submenu(0, "PanelVisibility")
	$EditorCamera.zoom_changed.connect($GameScene/EditorGridParallax/EditorGrid.queue_redraw)
	$EditHandler.placed_objects_collider = placed_objects_collider
	$EditHandler.editor_mode = %EditorModes
	$EditHandler.level = level
	LevelManager.editor_edited_level = level


func _physics_process(_delta: float) -> void:
	if LevelManager.level_playing:
		return
	placed_objects_collider.global_position = get_local_mouse_position()
	if get_viewport().gui_get_focus_owner() is not LineEdit:
		if Input.is_action_just_pressed(&"editor_place_mode"):
			%EditorModes.current_tab = 0
		elif Input.is_action_just_pressed(&"editor_edit_mode"):
			%EditorModes.current_tab = 1
		elif Input.is_action_just_pressed(&"editor_selection_filters_mode"):
			%EditorModes.current_tab = 2

	$EditorCamera.wrap_inset = get_viewport_rect().size - %EditorViewport.size
	if %EditorModes.get_current_tab_control().name == "Place" \
			and (Input.is_action_just_pressed(&"editor_add") or Input.is_action_just_pressed(&"editor_remove") \
			or Input.is_action_pressed(&"editor_add_swipe") or Input.is_action_pressed(&"editor_remove_swipe")):
		$PlaceHandler.handle_place(block_palette_button_group, placed_objects_collider, level)


func texture_variation_overlapping(type: EditorSelectionCollider.Type, id: int) -> bool:
	if not placed_objects_collider.has_overlapping_areas():
		return false
	if placed_objects_collider.get_overlapping_areas()[-1].get_parent() is Interactable \
			or placed_objects_collider.get_overlapping_areas()[-1].get_parent() is TriggerBase:
		return true
	if placed_objects_collider.get_overlapping_areas()[-1].type == type:
		return placed_objects_collider.get_overlapping_areas()[-1].id == id
	return false


func _on_playtest_pressed() -> void:
	$EditorCamera.enabled = not $EditorCamera.enabled
	$GameScene/PlayerCamera.enabled = not $GameScene/PlayerCamera.enabled
	if $GameScene/PlayerCamera.enabled:
		%EditorModes.hide()
		%SidePanel.hide()
		%EditorViewport.mouse_filter = MOUSE_FILTER_STOP
		$GameScene/Player.process_mode = Node.PROCESS_MODE_INHERIT
		$GameScene/EditorGridParallax/EditorGrid.hide()
		if not $EditHandler.selection.is_empty():
			$EditHandler.selection.map(EditHandler.remove_selection_highlight)
			$EditHandler.selection.clear()
		LevelManager.editor_level_backup.pack(level)
		LevelManager.editor_backup.pack(self)
		$GameScene._start_level()
	else:
		get_tree().change_scene_to_packed(LevelManager.editor_backup)


func _on_leave_pressed() -> void:
	var _fade_screen = $FadeScreenLayer/FadeScreen
	_fade_screen.show()
	_fade_screen.fade_in(0.5, Tween.EASE_IN, Tween.TRANS_SINE)
	create_tween().tween_property($EditorCamera, "zoom", $EditorCamera.zoom / 2, 0.5) \
			.set_ease(Tween.EASE_IN) \
			.set_trans(Tween.TRANS_EXPO)

