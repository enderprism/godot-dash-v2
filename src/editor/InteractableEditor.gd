extends PanelContainer
class_name InteractableEditor


func build_ui(interactables: Array[Interactable]) -> void:
	$MarginContainer.get_children().map(func(child): child.queue_free())
	var first_interactable := interactables[0]
	var ui_root := VBoxContainer.new()
	for component in first_interactable.components:
		var fields = component.script.get_script_property_list()
		fields.remove_at(0)
		fields = fields \
				.filter(func(field): return field["usage"] & PROPERTY_USAGE_EDITOR != 0)
		print_debug(component, ": ", fields)
		for field in fields:
			var field_name: String = field["name"]
			if field_name.begins_with("_"):
				continue
			var field_value = component.get(field_name)
			match typeof(field_value):
				TYPE_INT:
					if field["hint"] == PROPERTY_HINT_ENUM:
						var property := EnumProperty.new()
						property.name = field_name.to_pascal_case()
						property.fields = field["hint_string"].split(",")
						for i in property.fields.size():
							property.fields.set(i, property.fields[i].get_slice(":", 0))
						ui_root.add_child(property)
	$MarginContainer.add_child(ui_root)

	# connect_ui(interactables)
	# load_properties.call_deferred(first_interactable)


func connect_ui(interactables: Array[Interactable]) -> void:
	var properties := NodeUtils.get_children_of_type(%UIRoot, AbstractProperty, true) \
			.filter(func(node): return not node.owner.is_queued_for_deletion())
	if properties.is_empty():
		return
	for property in properties as Array[AbstractProperty]:
		var remove_connections := func(connection):
			if not "watcher" in connection.callable.get_method():
				property.value_changed.disconnect(connection.callable)
		property.value_changed.get_connections().map(remove_connections)
		var property_name := property.name.to_snake_case()
		if property.has_node("TriggerPropertyInternalName"):
			property_name = property.get_node("TriggerPropertyInternalName").property_name
		property.value_changed.connect(save_property.bind(property_name, interactables))


func save_property(value: Variant, property: String, interactables: Array[Interactable]) -> void:
	if property == "target_group":
		value = GroupEditor.GROUP_PREFIX + value
	interactables.map(func(interactable): interactable.set(property, value))


func load_properties(interactable: Interactable) -> void:
	var properties := NodeUtils.get_children_of_type(%UIRoot, AbstractProperty, true) \
			.filter(func(node): return not node.owner.is_queued_for_deletion())
	if properties.is_empty():
		return
	for property in properties as Array[AbstractProperty]:
		var property_name := property.name.to_snake_case()
		if property.has_node("TriggerPropertyInternalName"):
			property_name = property.get_node("TriggerPropertyInternalName").property_name
		if interactable.get(property_name) == null:
			printerr("Can't load property ", property_name, " on ", interactable)
			continue
		var value = interactable.get(property_name)
		property.set_value_no_signal(value)
