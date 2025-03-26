extends Node
class_name TriggerUIHandler

@export var multi_activate: Property
@export var spawn_triggered: Property
@export var touch_triggered: Property

func _on_edit_handler_selection_changed(selection:Array[Node2D]) -> void:
	if not is_selection_trigger_only(selection):
		return


func _on_spawn_triggered_value_changed(value: bool) -> void:
	touch_triggered.set_input_state(not value)


func _on_touch_triggered_value_changed(value:Variant) -> void:
	spawn_triggered.set_input_state(not value)


static func is_selection_trigger_only(selection: Array[Node2D]) -> bool:
	if selection.is_empty():
		return false
	var has_trigger := func(object: Node2D): return object.has_node("TriggerBase")
	return selection.filter(has_trigger) == selection
