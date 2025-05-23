@tool
extends BaseButton
class_name BouncyButton

# @export var selected_level: PackedScene
@export var block_palette_button: bool

func _ready() -> void:
	scale = Vector2.ONE
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
	if is_inside_tree():
		var scale_tween = create_tween()
		scale_tween.set_ease(Tween.EASE_OUT)
		scale_tween.set_trans(Tween.TRANS_BOUNCE)
		scale_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)

func _button_unheld() -> void:
	if is_inside_tree():
		var scale_tween = create_tween()
		scale_tween.set_ease(Tween.EASE_OUT)
		scale_tween.set_trans(Tween.TRANS_BOUNCE)
		scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
		release_focus()
