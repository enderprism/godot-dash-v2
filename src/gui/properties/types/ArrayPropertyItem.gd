@tool
extends AbstractProperty
class_name ArrayPropertyItem

signal value_changed(value: Variant)

var reorder_button: Button
var property: AbstractProperty
var delete_button: Button

var type: Script

func _ready() -> void:
	reorder_button = NodeUtils.get_node_or_add(self, "Reorder", Button, NodeUtils.INTERNAL)
	reorder_button.icon = preload("res://assets/textures/godot_editor_icons/TripleBar.png")
	reorder_button.keep_pressed_outside = true
	reorder_button.button_down.connect(reorder.bind(false))
	reorder_button.button_up.connect(reorder.bind(true))
	property = NodeUtils.get_node_or_add(self, "Property", type, NodeUtils.INTERNAL)
	property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_button = NodeUtils.get_node_or_add(self, "Delete", Button, NodeUtils.INTERNAL)
	delete_button.icon = preload("res://assets/textures/godot_editor_icons/Remove.png")
	for button in [reorder_button, delete_button]:
		button.custom_minimum_size.x = custom_minimum_size.y
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	property.name = name
	property.value_changed.connect(func(value): value_changed.emit(value))
	delete_button.pressed.connect(remove_self)
	renamed.connect(refresh)


func reorder(stop: bool) -> void:
	var parent_container := get_parent() as BoxContainer
	var parent_property := parent_container.get_meta("array_property") as ArrayProperty
	parent_property.reordered_item = self if not stop else null


func remove_self() -> void:
	var parent_container := get_parent() as BoxContainer
	var parent_property := parent_container.get_meta("array_property") as ArrayProperty
	parent_property.remove_item(get_index())


func refresh() -> void:
	property.name = name


func set_value(value: Variant) -> void:
	property.set_value(value)
	value_changed.emit(value)


func set_value_no_signal(value: Variant) -> void:
	property.set_value_no_signal(value)


func get_value() -> Variant:
	return property.get_value()
