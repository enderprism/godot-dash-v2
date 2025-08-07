@tool
extends AbstractProperty
class_name ResourceProperty

signal value_changed(value: Resource)

@export var default: Resource
@export var resource_script: Script:
	set(value):
		if value.new() is not Resource:
			resource_script = null
			push_error("Resource script does not extend Resource")
		resource_script = value
		default = value.new()
		default.resource_local_to_scene = true
@export_tool_button("Refresh") var _refresh = refresh

var label: Label
var indentation_container: VBoxContainer
var resource_properties: Array


func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	var margin_container = NodeUtils.get_node_or_add(
		NodeUtils.get_node_or_add(self, "PanelContainer", PanelContainer, NodeUtils.INTERNAL),
		"MarginContainer",
		MarginContainer,
		NodeUtils.INTERNAL) as MarginContainer
	margin_container.theme = preload("res://resources/Margins.tres");
	indentation_container = NodeUtils.get_node_or_add(
		margin_container,
		"VBoxContainer",
		VBoxContainer,
		NodeUtils.INTERNAL)
	resource_properties = resource_script.get_script_property_list()
	resource_properties.remove_at(0)
	resource_properties = resource_properties \
			.filter(func(property): return property["usage"] & PROPERTY_USAGE_EDITOR != 0) \
			.map(func(property): return property["name"])
	for child in get_children(false):
		child.hide()
		var child_duplicate = child.duplicate()
		child_duplicate.show()
		child_duplicate.value_changed.connect(func(value):
			if child_duplicate is Node2DProperty:
				if LevelManager.current_level == null:
					value = ^""
				else:
					value = LevelManager.current_level.get_path_to(value)
			print(Time.get_ticks_msec())
			print("old value: ", _value)
			_value = _value.duplicate(true)
			_value.set(resource_properties[child_duplicate.get_index()], value)
			print("new value: ", _value)
			value_changed.emit(_value))
		indentation_container.add_child(child_duplicate)
	renamed.connect(refresh)
	refresh()
	reset()


func refresh() -> void:
	label.text = name
	label.custom_minimum_size.y = custom_minimum_size.y
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vertical = true
	if Engine.is_editor_hint():
		reset()


func set_value(new_value: Resource) -> void:
	set_value_no_signal(new_value)
	value_changed.emit(new_value)


func set_value_no_signal(new_value: Resource) -> void:
	_value = new_value.duplicate(true)
	for i in indentation_container.get_child_count():
		var field_input = indentation_container.get_child(i)
		var field_name = resource_properties[i]
		var field_value = _value.get(field_name)
		if field_value == null and field_input is not Node2DProperty:
			continue
		if field_input is Node2DProperty:
			field_value = LevelManager.current_level.get_node(field_value)
		field_input.set_value_no_signal(field_value)


func get_value() -> Resource:
	return _value.duplicate(true)


func reset() -> void:
	set_value(default)


func set_input_state(enabled: bool) -> void:
	indentation_container.get_children().map(func(input): input.set_input_state(enabled))
