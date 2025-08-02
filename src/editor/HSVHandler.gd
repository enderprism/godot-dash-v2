extends Node
class_name HSVHandler


@export var hue: FloatProperty
@export var saturation: FloatProperty
@export var value: FloatProperty
@export var strength: FloatProperty
@export var alpha: FloatProperty
@export var editor_viewport: Control


func _process(_delta: float) -> void:
	if get_viewport().gui_get_focus_owner():
		var focused_property := get_viewport().gui_get_focus_owner().get_parent().get_parent() 
		if focused_property in [hue, saturation, value] and get_viewport().gui_get_hovered_control() == editor_viewport:
			editor_viewport.grab_focus()


func _has_hsv_watcher(object) -> bool:
	return object.has_node("HSVWatcher")


func _on_hue_value_changed(new_value: Variant) -> void:
	$"../EditHandler".selection.filter(_has_hsv_watcher).map(func(object): object.get_node("HSVWatcher").hsv_shift[0] = new_value)


func _on_saturation_value_changed(new_value: Variant) -> void:
	$"../EditHandler".selection.filter(_has_hsv_watcher).map(func(object): object.get_node("HSVWatcher").hsv_shift[1] = new_value)


func _on_value_value_changed(new_value: Variant) -> void:
	$"../EditHandler".selection.filter(_has_hsv_watcher).map(func(object): object.get_node("HSVWatcher").hsv_shift[2] = new_value)


func _on_strength_value_changed(new_value: Variant) -> void:
	$"../EditHandler".selection.filter(_has_hsv_watcher).map(func(object): object.get_node("HSVWatcher").strength = new_value)


func _on_alpha_value_changed(new_value: Variant) -> void:
	$"../EditHandler".selection.filter(_has_hsv_watcher).map(func(object): object.get_node("HSVWatcher").alpha = new_value)


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	if selection.is_empty():
		return
	var objects_with_hsv_watcher: Array[Node2D] = selection.filter(_has_hsv_watcher)
	if objects_with_hsv_watcher.is_empty():
		for property in [hue, saturation, value]:
			property.set_value(0.0)
		strength.set_value(1.0)
		alpha.set_value(1.0)
	else:
		var last_hsv_watcher = objects_with_hsv_watcher[-1].get_node("HSVWatcher")
		hue.set_value(last_hsv_watcher.hsv_shift[0])
		saturation.set_value(last_hsv_watcher.hsv_shift[1])
		value.set_value(last_hsv_watcher.hsv_shift[2])
		strength.set_value(last_hsv_watcher.strength)
		alpha.set_value(last_hsv_watcher.alpha)
