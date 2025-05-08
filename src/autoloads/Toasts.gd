extends Node

const TOAST_PACKED := preload("res://scenes/components/game_components/Toast.tscn")
const TOAST_LAYER_PACKED := preload("res://scenes/components/game_components/ToastLayer.tscn")

enum ToastOptions {
	NONE = 0,
	PERSISTENT = 1, # Doesn't disappear after a delay, the user must click on it to dismiss it.
}

var toast_layer: CanvasLayer
var toast_container: VBoxContainer


func new_toast(text: String, duration: float = 1.0, options: int = ToastOptions.NONE) -> Toast:
	if not get_tree().root.has_node("ToastLayer"):
		toast_layer = TOAST_LAYER_PACKED.instantiate() as CanvasLayer
		get_tree().root.add_child(toast_layer, true)
	else:
		toast_layer = get_tree().root.get_node("ToastLayer") as CanvasLayer
	toast_container = toast_layer.get_node(^"ToastContainer")
	var toast := TOAST_PACKED.instantiate() as PanelContainer
	toast.text = text
	toast.lifetime = duration
	toast.persistent = options & ToastOptions.PERSISTENT
	toast_container.add_child(toast)
	return toast
