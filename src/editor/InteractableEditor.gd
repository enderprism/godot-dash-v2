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
		for field in fields:
			var field_name: String = field["name"]
			if field_name.begins_with("_"):
				continue
			var field_value = component.get(field_name)
			var property: AbstractProperty
			match typeof(field_value):
				TYPE_INT:
					if field["hint"] == PROPERTY_HINT_ENUM:
						property = EnumProperty.new()
						property.fields = field["hint_string"].split(",")
						for i in property.fields.size():
							property.fields.set(i, property.fields[i].get_slice(":", 0))
						ui_root.add_child(property)
				TYPE_BOOL:
					property = BoolProperty.new()
			property.name = field_name.to_pascal_case()
			property.set_meta("component_name", component.name)
	$MarginContainer.add_child(ui_root)

	connect_ui(interactables, ui_root)
	load_properties.call_deferred(first_interactable, ui_root)


func connect_ui(interactables: Array[Interactable], ui_root: Control) -> void:
	var properties := NodeUtils.get_children_of_type(ui_root, AbstractProperty, true)
	if properties.is_empty():
		return
	for property in properties as Array[AbstractProperty]:
		var remove_connections := func(connection):
			if not "watcher" in connection.callable.get_method():
				property.value_changed.disconnect(connection.callable)
		property.value_changed.get_connections().map(remove_connections)
		var property_name := property.name.to_snake_case()
		property.value_changed.connect(save_property.bind(property.get_meta("component_name"), property_name, interactables))
		print(property.value_changed.get_connections())


func save_property(value: Variant, component_name: String, property: String, interactables: Array[Interactable]) -> void:
	prints(property, value, interactables)
	interactables.map(func(interactable): interactable.get_node(component_name).set(property, value))


func load_properties(interactable: Interactable, ui_root: Control) -> void:
	var properties := NodeUtils.get_children_of_type(ui_root, AbstractProperty, true)
	if properties.is_empty():
		return
	for property in properties as Array[AbstractProperty]:
		var property_name := property.name.to_snake_case()
		var component := interactable.get_node(String(property.get_meta("component_name")))
		if component.get(property_name) == null:
			printerr("Can't load property ", property_name, " on ", interactable)
			continue
		var value = component.get(property_name)
		property.set_value_no_signal(value)
