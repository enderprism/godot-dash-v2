extends Node

enum SubScene
{
	TITLE_SCREEN,
	LEVEL_SELECTOR,
	ICON_GARAGE,
	CREATED_LEVELS_LIST,
}

@export var _active_pcam: PhantomCamera2D # Active PhantomCamera2D when the scene enters the tree
var _current_subscene: SubScene = SubScene.TITLE_SCREEN

func _ready() -> void:
	_active_pcam.set_priority(GDPhantomCameraHistory.PhantomCameraStatus.CURRENT_ACTIVE)

func _process(_delta: float) -> void:
	if _current_subscene != SubScene.TITLE_SCREEN && Input.is_action_just_pressed("ui_cancel"):
		$PhantomCamera2DHistory._previous_phantomcamera(_active_pcam)
		_toggle_background_sprites_autoscroll(true)

func _on_go_to_level_selector_pressed() -> void:
	_current_subscene = SubScene.LEVEL_SELECTOR
	$PhantomCamera2DHistory._change_phantomcamera(_active_pcam, $"../LevelSelectorCamera")
	_toggle_background_sprites_autoscroll(false)

func _on_go_to_created_levels_list_pressed() -> void:
	_current_subscene = SubScene.CREATED_LEVELS_LIST
	$PhantomCamera2DHistory._change_phantomcamera(_active_pcam, $"../CreatedLevelsListCamera")
	_toggle_background_sprites_autoscroll(false)

func _on_go_to_icon_garage_pressed() -> void:
	_current_subscene = SubScene.ICON_GARAGE
	$PhantomCamera2DHistory._change_phantomcamera(_active_pcam, $"../IconGarageCamera")
	_toggle_background_sprites_autoscroll(false)

func _toggle_background_sprites_autoscroll(enabled: bool) -> void:
	if enabled:
		create_tween() \
			.tween_property($"../TitleScreen/Background", "autoscroll_speed:x", -300, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)
		create_tween() \
			.tween_property($"../TitleScreen/Ground", "autoscroll_speed:x", -800.0, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)
	else:
		create_tween() \
			.tween_property($"../TitleScreen/Background", "autoscroll_speed:x", 0.0, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)
		create_tween() \
			.tween_property($"../TitleScreen/Ground", "autoscroll_speed:x", 0.0, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)