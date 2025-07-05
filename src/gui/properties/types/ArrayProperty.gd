@tool
extends AbstractProperty
class_name ArrayProperty

signal value_changed(value: Array)

@export var default_size: int
@export var minimum_size: int = 1
@export var maximum_size: int = 10
@export var or_greater: bool
@export var item_type: Script:
	set(value):
		if value.new() is not AbstractProperty:
			item_type = null
			push_error("Item type does not extend AbstractProperty")
		item_type = value
@export_tool_button("Refresh") var _refresh = refresh

var label_container: HBoxContainer
var label: Label
var add: Button
var items: VBoxContainer


func _ready() -> void:
	_value = []
	vertical = true
	label_container = NodeUtils.get_node_or_add(self, "LabelContainer", HBoxContainer, NodeUtils.INTERNAL)
	label_container.custom_minimum_size.y = custom_minimum_size.y
	label = NodeUtils.get_node_or_add(label_container, "Label", Label, NodeUtils.INTERNAL)
	var spacer := NodeUtils.get_node_or_add(label_container, "Label", Label, NodeUtils.INTERNAL)
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	add = NodeUtils.get_node_or_add(label_container, "Add", Button, NodeUtils.INTERNAL)
	add.icon = preload("res://assets/textures/godot_editor_icons/Add.png")
	add.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add.custom_minimum_size.x = custom_minimum_size.y
	add.pressed.connect(add_item.bind(-1))
	items = NodeUtils.get_node_or_add(self, "Items", VBoxContainer, NodeUtils.INTERNAL)
	renamed.connect(refresh)
	refresh()


func refresh() -> void:
	label.text = name
	var array_size = items.get_child_count() if not Engine.is_editor_hint() else default_size
	array_size = minimum_size if array_size < minimum_size else array_size
	array_size = maximum_size if array_size > maximum_size and not or_greater else array_size
	if item_type == null:
		return
	items.visible = array_size > 0
	# Substractive
	if items.get_child_count() > array_size:
		for i in range(array_size, items.get_child_count()):
			items.get_child(i).queue_free()
		if array_size <= 0:
			items.hide()
		return
	# Additive
	for i in range(array_size):
		if items.get_child(i) != null:
			continue
		add_item(i)


func add_item(idx: int) -> ArrayPropertyItem:
	var item = ArrayPropertyItem.new()
	item.type = item_type
	item.name = str(idx if idx > 0 else items.get_child_count())
	items.add_child(item)
	_value.insert(idx, item.get_value())
	return item


func remove_item(idx: int) -> void:
	print_debug("item ", idx, " is being removed")
	var debug_color := Color.from_hsv(randf_range(0.0, 1.0), 0.9, 1.0)
	for i in range(idx, items.get_child_count()):
		var item = items.get_child(i)
		var new_name := i - 1
		item.name = str(new_name)
		item.refresh()
		item.property.name = item.name
		item.property.label.text = item.name
		item.property.refresh()
		prints(i, new_name)
		item.modulate = debug_color
	items.get_child(idx).queue_free()
	_value.remove_at(idx)


func set_value(value: Array) -> void:
	set_value_no_signal(value)
	value_changed.emit(value)


func set_value_no_signal(value: Array) -> void:
	_value = value
	items.get_children().map(func(item): item.queue_free())
	for i in range(len(value)):
		add_item(i).set_value_no_signal(value[i])


func get_value() -> Array:
	return _value
