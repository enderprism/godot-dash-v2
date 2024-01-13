@tool
extends BaseButton

@export var level_selector_button: bool :
	set(value):
		level_selector_button = value
		notify_property_list_changed()

@export var selected_level: String
@export var block_palette_button: bool
var _selected_level_scene: PackedScene

func _validate_property(property: Dictionary):
	if property.name == "selected_level" and not level_selector_button:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _ready() -> void:
	connect("button_down", Callable(self, "_button_held"))
	connect("button_up", Callable(self, "_button_unheld"))

func _physics_process(_delta: float) -> void:
	pivot_offset.x = size.x/2
	pivot_offset.y = size.y/2
	if block_palette_button:
		if is_pressed():
			modulate = Color("808080")
		else:
			modulate = Color("ffffff")

func _button_held() -> void:
	var scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_BOUNCE)
	scale_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)

func _button_unheld() -> void:
	var scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_BOUNCE)
	scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
