extends Node

const toast_scene := preload("res://scenes/components/game_components/Toast.tscn")

func new_toast(text: String) -> void:
	var toast := toast_scene.instantiate() as PanelContainer
	toast.get_node(^"%Label").text = text
	get_tree().current_scene.add_child(toast)
	var tween := toast.create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(toast, ^"modulate:a", 0.0, 0.2)
	tween.tween_callback(toast.queue_free)
