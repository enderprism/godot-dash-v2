extends PanelContainer
class_name Toast

var lifetime: float
var text: String
var persistent: bool


func _ready() -> void:
	update_text(text)
	if not persistent:
		$Timer.start(lifetime)
		$Timer.timeout.connect(dismiss)


func update_text(new_text: String) -> void:
	%Label.text = new_text


func dismiss() -> void:
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)


func _on_dismiss_pressed() -> void:
	dismiss()

