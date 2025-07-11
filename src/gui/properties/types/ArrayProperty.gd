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
var reordered_item: ArrayPropertyItem # Option<ArrayPropertyItem>
var reordering_tween: Tween

func _ready() -> void:
	_value = []
	vertical = true
	reordering_tween = create_tween()
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
	var margin_container: MarginContainer = NodeUtils.get_node_or_add(
		NodeUtils.get_node_or_add(self, "PanelContainer", PanelContainer, NodeUtils.INTERNAL),
		"MarginContainer",
		MarginContainer,
		NodeUtils.INTERNAL
	)
	margin_container.theme = preload("res://resources/Margins.tres")
	items = NodeUtils.get_node_or_add(margin_container, "Items", VBoxContainer, NodeUtils.INTERNAL)
	items.set_meta("array_property", self)
	renamed.connect(refresh)
	refresh()


func _process(_delta: float) -> void:
	if reordered_item == null:
		return
	var index: int = reordered_item.get_index()
	var new_index: int = -1 # Option<i32>
	# The actual positions of nodes within a container are kinda weird
	if get_local_mouse_position().y < reordered_item.position.y + reordered_item.size.y - 4.0:
		new_index = index - 1
	if index < items.get_child_count() - 1 and get_local_mouse_position().y > reordered_item.position.y + reordered_item.size.y * 2.0 + 8.0:
		new_index = index + 1
	if new_index == -1:
		return
	new_index = clampi(new_index, 0, items.get_child_count() - 1)
	items.move_child(reordered_item, new_index)
	# Avoid duplicate names (e.g. <idx>2)
	# I'm forced to apply a unique name to every item first,
	# and then put the actual index as the name, because
	# I can't find a universal way of doing it in one pass
	# without having duplicate names at an iteration.
	for item in items.get_children():
		item.name = str(hash(item))
	for item in items.get_children():
		item.name = str(item.get_index())


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
	if items.get_child_count() + 1 > maximum_size and not or_greater:
		return
	var item = ArrayPropertyItem.new()
	item.type = item_type
	item.name = str(idx if idx > 0 else items.get_child_count())
	items.add_child(item)
	_value.insert(idx, item.get_value())
	return item


func remove_item(idx: int) -> void:
	if items.get_child_count() - 1 < minimum_size:
		return
	for i in range(idx, items.get_child_count()):
		var item = items.get_child(i)
		# There is an issue where if we use `str(i - 1)` directly as the name,
		# the item doesn't get renamed correctly.
		# HACK: Adding a suffix fixes the renaming issue for some reason.
		# I'm using U+200B to avoid making the label wider.
		# Removing the suffix afterwards doesn't introduce the issue back.
		item.name = (str(i - 1) + "​").trim_prefix("​")
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
