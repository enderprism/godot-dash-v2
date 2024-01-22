extends ColorRect

signal fade_finished

var is_fading: bool

enum FADE_TYPE {
	FADE_IN,
	FADE_OUT
}

func _ready() -> void:
	color = Color("000000ff")
	hide()

func fade_in(fade_duration: float, ease_type: Tween.EaseType, trans_type: Tween.TransitionType) -> void:
	is_fading = true
	show()
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(self, "color", Color("000000ff"), fade_duration) \
		.set_ease(ease_type) \
		.set_trans(trans_type) \
		.from(Color("00000000"))
	await fade_tween.finished
	emit_signal("fade_finished", FADE_TYPE.FADE_IN)
	is_fading = false

func fade_out(fade_duration: float, ease_type: Tween.EaseType, trans_type: Tween.TransitionType) -> void:
	is_fading = true
	show()
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(self, "color", Color("00000000"), fade_duration) \
		.set_ease(ease_type) \
		.set_trans(trans_type) \
		.from(Color("000000ff"))
	await fade_tween.finished
	emit_signal("fade_finished", FADE_TYPE.FADE_OUT)
	hide()
	is_fading = false
