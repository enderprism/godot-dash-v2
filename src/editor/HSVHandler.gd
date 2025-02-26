extends Node
class_name HSVHandler


@export var hue: Property
@export var saturation: Property
@export var value: Property


func _on_hue_value_changed(new_value: Variant) -> void:
	$"../EditHandler".selection.map(func(object): NodeUtils.get_node_or_add(object, "HSVWatcher", HSVWatcher).hsv_shift[0] = new_value)


func _on_saturation_value_changed(new_value: Variant) -> void:
	$"../EditHandler".selection.map(func(object): NodeUtils.get_node_or_add(object, "HSVWatcher", HSVWatcher).hsv_shift[1] = new_value)


func _on_value_value_changed(new_value: Variant) -> void:
	$"../EditHandler".selection.map(func(object): NodeUtils.get_node_or_add(object, "HSVWatcher", HSVWatcher).hsv_shift[2] = new_value)


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	if selection.is_empty():
		return
	var objects_with_hsv_watcher: Array[Node2D] = selection.filter(func(object): return object.has_node("HSVWatcher"))
	if objects_with_hsv_watcher.is_empty():
		for property in [hue, saturation, value]:
			property.set_value(0.0, Property.Type.FLOAT)
	else:
		hue.set_value(objects_with_hsv_watcher[-1].get_node("HSVWatcher").hsv_shift[0], Property.Type.FLOAT)
		saturation.set_value(objects_with_hsv_watcher[-1].get_node("HSVWatcher").hsv_shift[1], Property.Type.FLOAT)
		value.set_value(objects_with_hsv_watcher[-1].get_node("HSVWatcher").hsv_shift[2], Property.Type.FLOAT)

