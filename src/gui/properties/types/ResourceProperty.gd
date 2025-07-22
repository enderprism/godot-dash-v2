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
@export_tool_button("Refresh") var _refresh = refresh

var label: Label
var indentation_container: VBoxContainer


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
	for child in get_children(false):
		child.hide()
		var child_duplicate = child.duplicate()
		child_duplicate.show()
		indentation_container.add_child(child_duplicate)
	renamed.connect(refresh)
	refresh()


func refresh() -> void:
	label.text = name
	label.custom_minimum_size.y = custom_minimum_size.y
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vertical = true
