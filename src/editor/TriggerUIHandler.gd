extends Node
class_name TriggerUIHandler

@export var trigger_editor: TriggerEditor
@export var single_usage: BoolProperty
@export var spawn_triggered: BoolProperty
@export var touch_triggered: BoolProperty

func _on_edit_handler_selection_changed(selection:Array[Node2D]) -> void:
	if not is_selection_trigger_only(selection):
		return
	var trigger_bases: Array = selection.map(func(object): return object.get_node("TriggerBase") as TriggerBase)
	var trigger_base := trigger_bases[0] as TriggerBase
	single_usage.set_value(trigger_base.single_usage)
	spawn_triggered.set_value(trigger_base._hitbox_shape == TriggerBase.TriggerHitboxShape.DISABLED)
	touch_triggered.set_value(trigger_base._hitbox_shape == TriggerBase.TriggerHitboxShape.SQUARE)
	spawn_triggered.set_input_state(trigger_base._hitbox_shape != TriggerBase.TriggerHitboxShape.SQUARE)
	touch_triggered.set_input_state(trigger_base._hitbox_shape != TriggerBase.TriggerHitboxShape.DISABLED)
	for property in [single_usage, spawn_triggered, touch_triggered]:
		property.value_changed.get_connections().map(func(connection): property.value_changed.disconnect(connection.callable))
	single_usage.value_changed.connect(_on_single_usage_value_changed.bind(trigger_bases))
	spawn_triggered.value_changed.connect(_on_spawn_triggered_value_changed.bind(trigger_bases))
	touch_triggered.value_changed.connect(_on_touch_triggered_value_changed.bind(trigger_bases))
	if not is_selection_same_trigger_type(selection):
		return
	var trigger_bases_typed: Array[TriggerBase]
	trigger_bases_typed.assign(trigger_bases)
	trigger_editor.build_ui(trigger_bases_typed)


func _on_single_usage_value_changed(value: bool, trigger_bases: Array) -> void:
	trigger_bases.map(func(trigger_base): trigger_base.single_usage = value)


func _on_spawn_triggered_value_changed(value: bool, trigger_bases: Array) -> void:
	touch_triggered.set_input_state(not value)
	if trigger_bases.is_empty():
		return
	var make_trigger_spawn_triggered := func(trigger_base: TriggerBase):
		trigger_base._hitbox_shape = TriggerBase.TriggerHitboxShape.DISABLED if value else TriggerBase.TriggerHitboxShape.LINE
	trigger_bases.map(make_trigger_spawn_triggered)


func _on_touch_triggered_value_changed(value:Variant, trigger_bases: Array) -> void:
	spawn_triggered.set_input_state(not value)
	if trigger_bases.is_empty():
		return
	var make_trigger_spawn_triggered := func(trigger_base: TriggerBase):
		trigger_base._hitbox_shape = TriggerBase.TriggerHitboxShape.SQUARE if value else TriggerBase.TriggerHitboxShape.LINE
	trigger_bases.map(make_trigger_spawn_triggered)


static func is_selection_trigger_only(selection: Array[Node2D]) -> bool:
	if selection.is_empty():
		return false
	var has_trigger := func(object: Node2D): return object.has_node("TriggerBase")
	return selection.filter(has_trigger) == selection

static func is_selection_same_trigger_type(selection: Array[Node2D]) -> bool:
	if selection.is_empty():
		return false
	var trigger_type = selection[0].get_script()
	var unmatching_trigger_types := selection.filter(func(trigger): return trigger.get_script() != trigger_type)
	return unmatching_trigger_types.is_empty()
