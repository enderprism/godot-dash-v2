extends Control

class_name EditorScene

func _ready() -> void:
	LevelManager.in_editor = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%MenuBar/View.set_item_submenu(0, "PanelVisibility")
	$MapCamera2D.enabled = true
	$GameScene/PlayerCamera.enabled = false
	$MapCamera2D.zoom_changed.connect($GameScene/EditorGridParallax/EditorGrid.queue_redraw)

func _on_button_pressed() -> void:
	$GameScene._start_level()