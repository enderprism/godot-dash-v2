extends Control

class_name EditorScene

@onready var level := LevelProps.new()
@onready var placed_objects_collider := $PlacedObjectsCollider as Area2D

func _ready() -> void:
	LevelManager.in_editor = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%MenuBar/View.set_item_submenu(0, "PanelVisibility")
	$MapCamera2D.enabled = true
	$GameScene/PlayerCamera.enabled = false
	$MapCamera2D.zoom_changed.connect($GameScene/EditorGridParallax/EditorGrid.queue_redraw)
	$GameScene/Level.add_child(level)

func _physics_process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		placed_objects_collider.global_position = get_local_mouse_position()
		if not placed_objects_collider.has_overlapping_bodies():
			# TODO: replace with selected object scene
			var object := preload("res://scenes/components/level_components/solids/DefaultCube.tscn").instantiate()
			object.position = (level.get_local_mouse_position() + Vector2(0, 64)).snapped(Vector2.ONE*128) - Vector2(0, 64)
			level.add_child(object)

func _on_button_pressed() -> void:
	$GameScene._start_level()