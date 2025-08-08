extends Node
class_name TriggerUIHandler

@export var trigger_editor: TriggerEditor
@export var interactable_editor: InteractableEditor
@export var single_usage: BoolProperty
@export var no_effects: BoolProperty
@export var trigger_hitbox_shape: EnumProperty
@export var trigger_hitbox_height: FloatProperty

func _on_edit_handler_selection_changed(selection:Array[Node2D]) -> void:
	if not is_selection_interactable_only(selection):
		return
	var trigger_bases: Array = selection.map(func(object): return object.get_node("TriggerBase") as TriggerBase)
	var interactables: Array = selection.map(into_interactable)
	single_usage.set_value_no_signal(interactables[0].single_usage)
	no_effects.set_value_no_signal(interactables[0].no_effects)
	var trigger_base := trigger_bases[0] as TriggerBase
	if trigger_base != null:
		trigger_hitbox_shape.set_value_no_signal(trigger_base._hitbox_shape)
		trigger_hitbox_height.set_value_no_signal(trigger_base.hitbox_height)
	for property in [single_usage, no_effects, trigger_hitbox_shape, trigger_hitbox_height]:
		property.value_changed.get_connections().map(func(connection): property.value_changed.disconnect(connection.callable))
	single_usage.value_changed.connect(_on_single_usage_value_changed.bind(interactables))
	no_effects.value_changed.connect(_on_no_effects_value_changed.bind(interactables))
	trigger_hitbox_shape.value_changed.connect(_on_trigger_hitbox_shape_value_changed.bind(trigger_bases))
	trigger_hitbox_height.value_changed.connect(_on_trigger_hitbox_height_value_changed.bind(trigger_bases))
	if not is_selection_same_interactable_type(selection):
		return
	if is_selection_trigger_only(selection):
		var trigger_bases_typed: Array[TriggerBase]
		trigger_bases_typed.assign(trigger_bases)
		trigger_editor.build_ui(trigger_bases_typed)
		return
	var interactables_typed: Array[Interactable]
	interactables_typed.assign(interactables)
	interactable_editor.build_ui(interactables_typed)


func _on_single_usage_value_changed(value: bool, interactables: Array) -> void:
	interactables.map(func(interactable): interactable.single_usage = value)


func _on_no_effects_value_changed(value: bool, interactables: Array) -> void:
	interactables.map(func(interactable): interactable.no_effects = value)


func _on_trigger_hitbox_shape_value_changed(value: TriggerBase.TriggerHitboxShape, trigger_bases: Array) -> void:
	if trigger_bases.is_empty():
		return
	trigger_hitbox_height.visible = value == TriggerBase.TriggerHitboxShape.LINE
	trigger_bases.map(func(trigger_base: TriggerBase): trigger_base._hitbox_shape = value)


func _on_trigger_hitbox_height_value_changed(value: float, trigger_bases: Array) -> void:
	if trigger_bases.is_empty():
		return
	trigger_bases.map(func(trigger_base: TriggerBase): trigger_base.hitbox_height = value)


static func into_interactable(object: Node2D) -> Interactable:
	if object.has_node(^"TriggerBase"):
		object = object.get_node(^"TriggerBase")
	return object if object is Interactable else null


static func is_selection_interactable_only(selection: Array[Node2D]) -> bool:
	if selection.is_empty():
		return false
	var is_interactable := func(object: Node2D): return object is Interactable or object.has_node(^"TriggerBase")
	return selection.filter(is_interactable) == selection


static func is_selection_same_interactable_type(selection: Array[Node2D]) -> bool:
	if selection.is_empty():
		return false
	var flatten := func(object): return object != null
	var trigger_type = selection[0].get_script()
	var unmatching_trigger_types := selection.filter(func(trigger): return trigger.get_script() != trigger_type)
	var interactables := selection.map(into_interactable).filter(flatten)
	var matching_components: Array[Component] = interactables[0].components
	var unmatching_interactables := interactables.filter(func(interactable): return interactable.components != matching_components)
	return unmatching_trigger_types.is_empty() or unmatching_interactables.is_empty()


static func is_selection_trigger_only(selection: Array[Node2D]) -> bool:
	if selection.is_empty():
		return false
	var has_trigger := func(object: Node2D): return object.has_node(^"TriggerBase")
	return selection.filter(has_trigger) == selection
