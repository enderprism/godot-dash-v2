@tool extends Node

enum SubScene {
	TITLE_SCREEN,
	LEVEL_SELECTOR,
	ICON_GARAGE,
	CREATED_LEVELS_LIST,
}

@export var active_pcam: PhantomCamera2D # Active PhantomCamera2D when the scene enters the tree
@export var history: GDPhantomCameraHistory
@export var page_control_container: Control
@export var quit_game_button: Button
@export var fade_screen_layer: CanvasLayer

@export_group("Subscenes")
@export var created_levels_list: Control
@export var icon_garage: Control
@export var level_selector: Control

@export_group("PhantomCameras")
@export var created_levels_list_camera: PhantomCamera2D
@export var icon_garage_camera: PhantomCamera2D
@export var quit_game_camera: PhantomCamera2D
@export var title_screen_camera: PhantomCamera2D

@export_group("Title Screen Components")
@export var title_screen_background: Parallax2D
@export var title_screen_ground: Parallax2D

@export_group("Level Selector Components")
@export var level_selector_page_container: Control

var _current_subscene: SubScene = SubScene.TITLE_SCREEN
var _level_selector_tab_idx: int
var _hide_page_control: bool = true


@onready var _base_background_color: Color = title_screen_background.get_node("Background").modulate

func _ready() -> void:
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	icon_garage.position.x = -icon_garage.size.x
	created_levels_list.position.x = created_levels_list.size.x
	level_selector.size.x = icon_garage.size.x * level_selector_page_container.get_child_count()
	level_selector.position.y = -icon_garage.size.y
	page_control_container.hide()
	page_control_container.modulate.a = 0.0
	created_levels_list.hide()
	icon_garage.hide()
	level_selector.hide()
	active_pcam.set_priority(GDPhantomCameraHistory.PhantomCameraStatus.CURRENT_ACTIVE)

func _return_to_title_screen() -> void:
	history._previous_phantomcamera(active_pcam)
	_toggle_background_sprites_autoscroll(true)
	if page_control_container.modulate != Color("ffffff00"):
		_hide_page_control = true
	if active_pcam == title_screen_camera: _current_subscene = SubScene.TITLE_SCREEN
	_change_background_color(_base_background_color)
	await title_screen_camera.tween_completed
	created_levels_list.hide()
	icon_garage.hide()
	level_selector.hide()

func _process(_delta: float) -> void:
	if _current_subscene == SubScene.LEVEL_SELECTOR:
		if Input.is_action_just_pressed("ui_left"): _on_previous_level_pressed()
		if Input.is_action_just_pressed("ui_right"): _on_next_level_pressed()
	if _current_subscene == SubScene.TITLE_SCREEN && Input.is_action_just_pressed("ui_cancel"):
		_on_quit_game_pressed()
	if _current_subscene != SubScene.TITLE_SCREEN && Input.is_action_just_pressed("ui_cancel"):
		_return_to_title_screen()

	if _hide_page_control:
		page_control_container.modulate.a = lerpf(page_control_container.modulate.a, 0.0, 0.3)
		quit_game_button.modulate.a = lerpf(quit_game_button.modulate.a, 1.0, 0.3)
		if is_zero_approx(page_control_container.modulate.a):
			page_control_container.hide()
		if not is_zero_approx(quit_game_button.modulate.a):
			quit_game_button.show()
	else:
		if not is_zero_approx(page_control_container.modulate.a):
			page_control_container.show()
		if is_zero_approx(quit_game_button.modulate.a):
			quit_game_button.hide()
		page_control_container.modulate.a = lerpf(page_control_container.modulate.a, 1.0, 0.3)
		quit_game_button.modulate.a = lerpf(quit_game_button.modulate.a, 0.0, 0.3)

func _on_go_to_level_selector_pressed() -> void:
	level_selector.show()
	created_levels_list.hide()
	icon_garage.hide()
	_current_subscene = SubScene.LEVEL_SELECTOR
	_change_background_color(
		level_selector_page_container \
				.get_child(_level_selector_tab_idx) \
				.self_modulate
	)
	history._change_phantomcamera(
		active_pcam, \
		level_selector_page_container \
				.get_child(_level_selector_tab_idx) \
				.get_node("%LevelSelectorTabCamera") \
	)
	_hide_page_control = false
	_toggle_background_sprites_autoscroll(false)

func _on_go_to_created_levels_list_pressed() -> void:
	level_selector.hide()
	created_levels_list.show()
	icon_garage.hide()
	_current_subscene = SubScene.CREATED_LEVELS_LIST
	history._change_phantomcamera(active_pcam, created_levels_list_camera)
	_toggle_background_sprites_autoscroll(false)

func _on_go_to_icon_garage_pressed() -> void:
	level_selector.hide()
	created_levels_list.hide()
	icon_garage.show()
	_current_subscene = SubScene.ICON_GARAGE
	history._change_phantomcamera(active_pcam, icon_garage_camera)
	_toggle_background_sprites_autoscroll(false)

func _toggle_background_sprites_autoscroll(enabled: bool) -> void:
	# HACK: autoscroll can't be interpolated
	if enabled:
		# create_tween() \
		# 	.tween_property(title_screen_background, "autoscroll:x", -300, 1.0) \
		# 	.set_ease(Tween.EASE_OUT) \
		# 	.set_trans(Tween.TRANS_EXPO)
		# create_tween() \
		# 	.tween_property(title_screen_ground, "autoscroll:x", -800.0, 1.0) \
		# 	.set_ease(Tween.EASE_OUT) \
		# 	.set_trans(Tween.TRANS_EXPO)
		title_screen_background.autoscroll.x = -300
		title_screen_ground.autoscroll.x = -800
	else:
		# create_tween() \
		# 	.tween_property(title_screen_background, "autoscroll:x", 0.0, 1.0) \
		# 	.set_ease(Tween.EASE_OUT) \
		# 	.set_trans(Tween.TRANS_EXPO)
		# create_tween() \
		# 	.tween_property(title_screen_ground, "autoscroll:x", 0.0, 1.0) \
		# 	.set_ease(Tween.EASE_OUT) \
		# 	.set_trans(Tween.TRANS_EXPO)
		title_screen_background.autoscroll.x = 0
		title_screen_ground.autoscroll.x = 0

func _change_background_color(new_color: Color) -> void:
	create_tween() \
			.tween_property(title_screen_background.get_node("Background"), "modulate", new_color, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)


func _on_previous_level_pressed() -> void:
	_level_selector_tab_idx -= 1
	_level_selector_tab_idx %= level_selector_page_container.get_child_count()
	history._change_phantomcamera(
		active_pcam, \
		level_selector_page_container \
				.get_child(_level_selector_tab_idx) \
				.get_node("%LevelSelectorTabCamera") \
	)
	_change_background_color(
		level_selector_page_container \
				.get_child(_level_selector_tab_idx) \
				.self_modulate
	)


func _on_next_level_pressed() -> void:
	_level_selector_tab_idx += 1
	_level_selector_tab_idx %= level_selector_page_container.get_child_count()
	history._change_phantomcamera(
		active_pcam, \
		level_selector_page_container \
				.get_child(_level_selector_tab_idx) \
				.get_node("%LevelSelectorTabCamera") \
	)
	_change_background_color(
		level_selector_page_container \
				.get_child(_level_selector_tab_idx) \
				.self_modulate
	)


func _on_quit_game_pressed() -> void:
	var _fade_screen = fade_screen_layer.get_child(0)
	if not _fade_screen.is_fading:
		_fade_screen.fade_in(1.0, Tween.EASE_IN_OUT, Tween.TRANS_EXPO)
		history._change_phantomcamera(active_pcam, quit_game_camera)
		await _fade_screen.fade_finished
		get_tree().quit()

func _on_back_button_pressed() -> void:
	_return_to_title_screen()
