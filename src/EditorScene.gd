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

func _ready() -> void:
	LevelManager.level_playing = false
	$EditorCamera.enabled = true
	$GameScene/PlayerCamera.enabled = false
	$GameScene/EditorGridParallax/EditorGrid.queue_redraw()

	if LevelManager.entering_editor:
		LevelManager.entering_editor = false
		var _fade_screen = $FadeScreenLayer/FadeScreen
		_fade_screen.fade_out(0.5, Tween.EASE_OUT, Tween.TRANS_EXPO)
		create_tween().tween_property($EditorCamera, "zoom", Vector2.ONE * 0.8, 0.5)\
				.set_ease(Tween.EASE_OUT) \
				.set_trans(Tween.TRANS_EXPO) \
				.from(Vector2.ONE * 0.4)
	LevelManager.in_editor = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%MenuBar/View.set_item_submenu(0, "PanelVisibility")
	$EditorCamera.zoom_changed.connect($GameScene/EditorGridParallax/EditorGrid.queue_redraw)
	$GameScene/Level.add_child(level)
	set_process_input(false)
	set_process_unhandled_input(true)

func _physics_process(_delta: float) -> void:
	placed_objects_collider.global_position = get_local_mouse_position()

	if Input.is_action_just_pressed(&"editor_place_mode"):
		%EditorModes.current_tab = 0
	elif Input.is_action_just_pressed(&"editor_edit_mode"):
		%EditorModes.current_tab = 1
	elif Input.is_action_just_pressed(&"editor_selection_filters_mode"):
		%EditorModes.current_tab = 2

	if get_viewport().gui_get_hovered_control() == null:
		if Input.is_action_just_pressed(&"editor_add") or Input.is_action_just_pressed(&"editor_remove") \
				or Input.is_action_pressed(&"editor_add_swipe") or Input.is_action_pressed(&"editor_remove_swipe") \
				or (editor_actions & EditorAction.SWIPE and (Input.is_action_pressed(&"editor_add") or Input.is_action_pressed(&"editor_remove"))):
			# Handle object placement
			var pressed_button := block_palette_button_group.get_pressed_button()
			var block_palette_ref: BlockPaletteRef
			if pressed_button != null:
				block_palette_ref = pressed_button.get_node_or_null("BlockPaletteRef") as BlockPaletteRef
			if block_palette_ref != null and not _is_object_of_id_overlapping(block_palette_ref.type, block_palette_ref.id) \
					and Input.is_action_pressed(&"editor_add"):
				if pressed_button != null:
					var object: Node2D = pressed_button.get_node_or_null("BlockPaletteRef").object.instantiate()
					if pressed_button.has_node("BlockPaletteTextureSwap"):
						var block_palette_texture_swap := pressed_button.get_node("BlockPaletteTextureSwap") as BlockPaletteTextureSwap
						var texture_owner: NodePath = block_palette_texture_swap.texture_owner
						var texture_override: Texture = block_palette_texture_swap.texture_override
						object.get_node(block_palette_texture_swap.texture_owner).texture = texture_override
						object.get_node("EditorSelectionCollider").id = block_palette_ref.id
					object.position = (level.get_local_mouse_position() + Vector2(0, 64)).snapped(Vector2.ONE*128) - Vector2(0, 64)
					level.add_child(object)
			# Handle object deletion
			elif Input.is_action_pressed(&"editor_remove") and placed_objects_collider.has_overlapping_areas():
				if len(placed_objects_collider.get_overlapping_areas()) > 0:
					placed_objects_collider.get_overlapping_areas()[-1].get_parent().queue_free()

func _is_object_of_id_overlapping(type: EditorSelectionCollider.Type, id: int) -> bool:
	if not placed_objects_collider.has_overlapping_areas():
		return false
	if placed_objects_collider.get_overlapping_areas()[-1].get_parent() is Interactable:
		return true
	if placed_objects_collider.get_overlapping_areas()[-1].type == type:
		return placed_objects_collider.get_overlapping_areas()[-1].id == id
	return false


func _on_button_pressed() -> void:
	$GameScene._start_level()
	$EditorCamera.enabled = not $EditorCamera.enabled
	$GameScene/PlayerCamera.enabled = not $GameScene/PlayerCamera.enabled