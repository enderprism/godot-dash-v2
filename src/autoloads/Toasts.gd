extends Node

const TOAST_PACKED := preload("res://scenes/components/game_components/Toast.tscn")
const TOAST_LAYER_PACKED := preload("res://scenes/components/game_components/ToastLayer.tscn")

var toast_layer: CanvasLayer
var toast_container: VBoxContainer


func new_toast(text: String) -> void:
	if not get_tree().root.has_node("ToastLayer"):
		toast_layer = TOAST_LAYER_PACKED.instantiate() as CanvasLayer
		get_tree().root.add_child(toast_layer, true)
	else:
		toast_layer = get_tree().root.get_node("ToastLayer") as CanvasLayer
	toast_container = toast_layer.get_node(^"ToastContainer")
	var toast := TOAST_PACKED.instantiate() as PanelContainer
	toast.get_node(^"%Label").text = text
	toast_container.add_child(toast)
	var tween := toast.create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(toast, ^"modulate:a", 0.0, 0.2)
	tween.tween_callback(toast.queue_free)
