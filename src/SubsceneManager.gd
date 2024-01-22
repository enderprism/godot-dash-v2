extends Node

enum SubScene {
	TITLE_SCREEN,
	LEVEL_SELECTOR,
	ICON_GARAGE,
	CREATED_LEVELS_LIST,
}

@export var _active_pcam: PhantomCamera2D # Active PhantomCamera2D when the scene enters the tree
@onready var _page_control_container: Control = $"../LevelSelector/CanvasLayer/PageControlContainer"
@onready var _base_background_color: Color = $"../TitleScreen/Background".modulate
@onready var _quit_game: Button = $"../TitleScreen/Control/QuitGame"
var _current_subscene: SubScene = SubScene.TITLE_SCREEN
var _level_selector_tab_idx: int
var _hide_page_control: bool = true


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_page_control_container.hide()
	_page_control_container.modulate.a = 0.0
	$"../CreatedLevelsList".hide()
	$"../IconGarage".hide()
	$"../LevelSelector".hide()
	_active_pcam.set_priority(GDPhantomCameraHistory.PhantomCameraStatus.CURRENT_ACTIVE)

func _return_to_title_screen() -> void:
	$PhantomCamera2DHistory._previous_phantomcamera(_active_pcam)
	_toggle_background_sprites_autoscroll(true)
	if _page_control_container.modulate != Color("ffffff00"):
		_hide_page_control = true
	if _active_pcam == $"../TitleScreenCamera": _current_subscene = SubScene.TITLE_SCREEN
	_change_background_color(_base_background_color)
	await $"../TitleScreenCamera".tween_completed
	$"../CreatedLevelsList".hide()
	$"../IconGarage".hide()
	$"../LevelSelector".hide()

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
		_quit_game.modulate.a = lerpf(_quit_game.modulate.a, 1.0, 0.3)
		if is_zero_approx(_page_control_container.modulate.a):
			_page_control_container.hide()
		if not is_zero_approx(_quit_game.modulate.a):
			_quit_game.show()
	else:
		if not is_zero_approx(_page_control_container.modulate.a):
			_page_control_container.show()
		if is_zero_approx(_quit_game.modulate.a):
			_quit_game.hide()
		_page_control_container.modulate.a = lerpf(_page_control_container.modulate.a, 1.0, 0.3)
		_quit_game.modulate.a = lerpf(_quit_game.modulate.a, 0.0, 0.3)

func _on_go_to_level_selector_pressed() -> void:
	$"../LevelSelector".show()
	$"../CreatedLevelsList".hide()
	$"../IconGarage".hide()
	_current_subscene = SubScene.LEVEL_SELECTOR
	_change_background_color(
		$"../LevelSelector/PageContainer" \
		.get_child(_level_selector_tab_idx) \
		.self_modulate
	)
	$PhantomCamera2DHistory._change_phantomcamera(
		_active_pcam, \
		$"../LevelSelector/PageContainer" \
			.get_child(_level_selector_tab_idx) \
			.get_node("LevelSelectorTabCamera") \
	)
	_hide_page_control = false
	_toggle_background_sprites_autoscroll(false)

func _on_go_to_created_levels_list_pressed() -> void:
	$"../LevelSelector".hide()
	$"../CreatedLevelsList".show()
	$"../IconGarage".hide()
	_current_subscene = SubScene.CREATED_LEVELS_LIST
	$PhantomCamera2DHistory._change_phantomcamera(_active_pcam, $"../CreatedLevelsListCamera")
	_toggle_background_sprites_autoscroll(false)

func _on_go_to_icon_garage_pressed() -> void:
	$"../LevelSelector".hide()
	$"../CreatedLevelsList".hide()
	$"../IconGarage".show()
	_current_subscene = SubScene.ICON_GARAGE
	$PhantomCamera2DHistory._change_phantomcamera(_active_pcam, $"../IconGarageCamera")
	_toggle_background_sprites_autoscroll(false)

func _toggle_background_sprites_autoscroll(enabled: bool) -> void:
	if enabled:
		create_tween() \
			.tween_property($"../TitleScreen/Background", "_autoscroll_speed:x", -300, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)
		create_tween() \
			.tween_property($"../TitleScreen/Ground", "_autoscroll_speed:x", -800.0, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)
	else:
		create_tween() \
			.tween_property($"../TitleScreen/Background", "_autoscroll_speed:x", 0.0, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)
		create_tween() \
			.tween_property($"../TitleScreen/Ground", "_autoscroll_speed:x", 0.0, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)

func _change_background_color(new_color: Color) -> void:
	create_tween() \
		.tween_property($"../TitleScreen/Background", "modulate", new_color, 1.0) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_EXPO)


func _on_previous_level_pressed() -> void:
	_level_selector_tab_idx -= 1
	_level_selector_tab_idx %= $"../LevelSelector/PageContainer".get_child_count()
	$PhantomCamera2DHistory._change_phantomcamera(
		_active_pcam, \
		$"../LevelSelector/PageContainer" \
			.get_child(_level_selector_tab_idx) \
			.get_node("LevelSelectorTabCamera") \
	)
	_change_background_color(
		$"../LevelSelector/PageContainer" \
		.get_child(_level_selector_tab_idx) \
		.self_modulate
	)


func _on_next_level_pressed() -> void:
	_level_selector_tab_idx += 1
	_level_selector_tab_idx %= $"../LevelSelector/PageContainer".get_child_count()
	$PhantomCamera2DHistory._change_phantomcamera(
		_active_pcam, \
		$"../LevelSelector/PageContainer" \
			.get_child(_level_selector_tab_idx) \
			.get_node("LevelSelectorTabCamera") \
	)
	_change_background_color(
		$"../LevelSelector/PageContainer" \
		.get_child(_level_selector_tab_idx) \
		.self_modulate
	)


func _on_quit_game_pressed() -> void:
	var _fade_screen = $"../FadeScreenLayer/FadeScreen"
	if not _fade_screen.is_fading:
		_fade_screen.fade_in(1.0, Tween.EASE_IN_OUT, Tween.TRANS_EXPO)
		$PhantomCamera2DHistory._change_phantomcamera(_active_pcam, $"../QuitGameCamera")
		await _fade_screen.fade_finished
		get_tree().quit()

func _on_back_button_pressed() -> void:
	_return_to_title_screen()
