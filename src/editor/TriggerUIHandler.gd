extends Node
class_name TriggerUIHandler

@export var trigger_editor: TriggerEditor
@export var multi_activate: Property
@export var spawn_triggered: Property
@export var touch_triggered: Property

func _on_edit_handler_selection_changed(selection:Array[Node2D]) -> void:
	if not is_selection_trigger_only(selection):
		return
	var trigger: TriggerBase = selection[0].get_node("TriggerBase")
	_on_spawn_triggered_value_changed(trigger._hitbox_shape == TriggerBase.TriggerHitboxShape.DISABLED)
	_on_touch_triggered_value_changed(trigger._hitbox_shape == TriggerBase.TriggerHitboxShape.SQUARE)
	var trigger_bases: Array[TriggerBase] = selection.map(func(object): return object.get_node("TriggerBase") as TriggerBase)
	spawn_triggered.value_changed.connect(_on_spawn_triggered_value_changed.bind(trigger_bases))
	touch_triggered.value_changed.connect(_on_touch_triggered_value_changed.bind(trigger_bases))
	if len(selection) != 1:
		return
	trigger_editor.build_ui(trigger)


func _on_spawn_triggered_value_changed(value: bool, triggers: Array = []) -> void:
	touch_triggered.set_input_state(not value)
	if triggers.is_empty():
		return
	var make_trigger_spawn_triggered := func(trigger_base: TriggerBase):
		trigger_base._hitbox_shape = TriggerBase.TriggerHitboxShape.DISABLED if value else TriggerBase.TriggerHitboxShape.LINE
	triggers.map(make_trigger_spawn_triggered)


func _on_touch_triggered_value_changed(value:Variant, triggers: Array = []) -> void:
	spawn_triggered.set_input_state(not value)
	if triggers.is_empty():
		return
	var make_trigger_spawn_triggered := func(trigger_base: TriggerBase):
		trigger_base._hitbox_shape = TriggerBase.TriggerHitboxShape.SQUARE if value else TriggerBase.TriggerHitboxShape.LINE
	triggers.map(make_trigger_spawn_triggered)


static func is_selection_trigger_only(selection: Array[Node2D]) -> bool:
	if selection.is_empty():
		return false
	var has_trigger := func(object: Node2D): return object.has_node("TriggerBase")
	return selection.filter(has_trigger) == selection
