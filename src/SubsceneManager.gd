@tool extends Node

enum SubScene {
	TITLE_SCREEN,
	LEVEL_SELECTOR,
	ICON_GARAGE,
	CREATED_LEVELS_LIST,
}

@export var _active_pcam: PhantomCamera2D # Active PhantomCamera2D when the scene enters the tree
@export var _history: GDPhantomCameraHistory
@export var _page_control_container: Control
@export var _quit_game_button: Button
@export var _fade_screen_layer: CanvasLayer

@export_group("Subscenes")
@export var _created_levels_list: Control
@export var _icon_garage: Control
@export var _level_selector: Control

@export_group("PhantomCameras")
@export var _created_levels_list_camera: PhantomCamera2D
@export var _icon_garage_camera: PhantomCamera2D
@export var _quit_game_camera: PhantomCamera2D
@export var _title_screen_camera: PhantomCamera2D

@export_group("Title Screen Components")
@export var _title_screen_background: Sprite2D
@export var _title_screen_ground: Sprite2D

@export_group("Level Selector Components")
@export var _level_selector_page_container: Control

@onready var _base_background_color: Color = _title_screen_background.modulate

var _current_subscene: SubScene = SubScene.TITLE_SCREEN
var _level_selector_tab_idx: int
var _hide_page_control: bool = true


func _ready() -> void:
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_icon_garage.position.x = -_icon_garage.size.x
	_created_levels_list.position.x = _created_levels_list.size.x
	_level_selector.size.x = _icon_garage.size.x * _level_selector_page_container.get_child_count()
	_level_selector.position.y = -_icon_garage.size.y
	_page_control_container.hide()
	_page_control_container.modulate.a = 0.0
	_created_levels_list.hide()
	_icon_garage.hide()
	_level_selector.hide()
	_active_pcam.set_priority(GDPhantomCameraHistory.PhantomCameraStatus.CURRENT_ACTIVE)

func _return_to_title_screen() -> void:
	_history._previous_phantomcamera(_active_pcam)
	_toggle_background_sprites_autoscroll(true)
	if _page_control_container.modulate != Color("ffffff00"):
		_hide_page_control = true
	if _active_pcam == _title_screen_camera: _current_subscene = SubScene.TITLE_SCREEN
	_change_background_color(_base_background_color)
	await _title_screen_camera.tween_completed
	_created_levels_list.hide()
	_icon_garage.hide()
	_level_selector.hide()

func _process(_delta: float) -> void:
	if _current_subscene == SubScene.LEVEL_SELECTOR:
		if Input.is_action_just_pressed("ui_left"): _on_previous_level_pressed()
		if Input.is_action_just_pressed("ui_right"): _on_next_level_pressed()
	if _current_subscene == SubScene.TITLE_SCREEN && Input.is_action_just_pressed("ui_cancel"):
		_on_quit_game_pressed()
	if _current_subscene != SubScene.TITLE_SCREEN && Input.is_action_just_pressed("ui_cancel"):
		_return_to_title_screen()

	if _hide_page_control:
		_page_control_container.modulate.a = lerpf(_page_control_container.modulate.a, 0.0, 0.3)
		_quit_game_button.modulate.a = lerpf(_quit_game_button.modulate.a, 1.0, 0.3)
		if is_zero_approx(_page_control_container.modulate.a):
			_page_control_container.hide()
		if not is_zero_approx(_quit_game_button.modulate.a):
			_quit_game_button.show()
	else:
		if not is_zero_approx(_page_control_container.modulate.a):
			_page_control_container.show()
		if is_zero_approx(_quit_game_button.modulate.a):
			_quit_game_button.hide()
		_page_control_container.modulate.a = lerpf(_page_control_container.modulate.a, 1.0, 0.3)
		_quit_game_button.modulate.a = lerpf(_quit_game_button.modulate.a, 0.0, 0.3)

func _on_go_to_level_selector_pressed() -> void:
	_level_selector.show()
	_created_levels_list.hide()
	_icon_garage.hide()
	_current_subscene = SubScene.LEVEL_SELECTOR
	_change_background_color(
		_level_selector_page_container \
		.get_child(_level_selector_tab_idx) \
		.self_modulate
	)
	_history._change_phantomcamera(
		_active_pcam, \
		_level_selector_page_container \
			.get_child(_level_selector_tab_idx) \
			.get_node("%LevelSelectorTabCamera") \
	)
	_hide_page_control = false
	_toggle_background_sprites_autoscroll(false)

func _on_go_to_created_levels_list_pressed() -> void:
	_level_selector.hide()
	_created_levels_list.show()
	_icon_garage.hide()
	_current_subscene = SubScene.CREATED_LEVELS_LIST
	_history._change_phantomcamera(_active_pcam, _created_levels_list_camera)
	_toggle_background_sprites_autoscroll(false)

func _on_go_to_icon_garage_pressed() -> void:
	_level_selector.hide()
	_created_levels_list.hide()
	_icon_garage.show()
	_current_subscene = SubScene.ICON_GARAGE
	_history._change_phantomcamera(_active_pcam, _icon_garage_camera)
	_toggle_background_sprites_autoscroll(false)

func _toggle_background_sprites_autoscroll(enabled: bool) -> void:
	if enabled:
		create_tween() \
			.tween_property(_title_screen_background, "_autoscroll_speed:x", -300, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)
		create_tween() \
			.tween_property(_title_screen_ground, "_autoscroll_speed:x", -800.0, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)
	else:
		create_tween() \
			.tween_property(_title_screen_background, "_autoscroll_speed:x", 0.0, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)
		create_tween() \
			.tween_property(_title_screen_ground, "_autoscroll_speed:x", 0.0, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)

func _change_background_color(new_color: Color) -> void:
	create_tween() \
		.tween_property(_title_screen_background, "modulate", new_color, 1.0) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_EXPO)


func _on_previous_level_pressed() -> void:
	_level_selector_tab_idx -= 1
	_level_selector_tab_idx %= _level_selector_page_container.get_child_count()
	_history._change_phantomcamera(
		_active_pcam, \
		_level_selector_page_container \
			.get_child(_level_selector_tab_idx) \
			.get_node("%LevelSelectorTabCamera") \
	)
	_change_background_color(
		_level_selector_page_container \
		.get_child(_level_selector_tab_idx) \
		.self_modulate
	)


func _on_next_level_pressed() -> void:
	_level_selector_tab_idx += 1
	_level_selector_tab_idx %= _level_selector_page_container.get_child_count()
	_history._change_phantomcamera(
		_active_pcam, \
		_level_selector_page_container \
			.get_child(_level_selector_tab_idx) \
			.get_node("%LevelSelectorTabCamera") \
	)
	_change_background_color(
		_level_selector_page_container \
		.get_child(_level_selector_tab_idx) \
		.self_modulate
	)


func _on_quit_game_pressed() -> void:
	var _fade_screen = _fade_screen_layer.get_child(0)
	if not _fade_screen.is_fading:
		_fade_screen.fade_in(1.0, Tween.EASE_IN_OUT, Tween.TRANS_EXPO)
		_history._change_phantomcamera(_active_pcam, _quit_game_camera)
		await _fade_screen.fade_finished
		get_tree().quit()

func _on_back_button_pressed() -> void:
	_return_to_title_screen()
