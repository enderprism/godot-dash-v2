extends PanelContainer
class_name InteractableEditor

const COMPONENT_WHITELIST: Array[StringName] = [&"DirectionChangerComponent", &"GamemodeChangerComponent", &"ToggleComponent", &"TeleportComponent"]


func build_ui(interactables: Array[Interactable]) -> void:
	$MarginContainer.get_children().map(func(child): child.queue_free())
	var first_interactable := interactables[0]
	var ui_root := VBoxContainer.new()
	for component in first_interactable.components:
		var component_section := SectionHeading.new()
		component_section.name = component.name.trim_suffix("Component").capitalize()
		component_section.label_settings = preload("res://resources/SectionHeadings.tres")
		component_section.label_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if component.get_script().get_global_name() not in COMPONENT_WHITELIST:
			continue
		var fields = component.script.get_script_property_list()
		fields.remove_at(0)
		fields = fields \
				.filter(func(field): return field["usage"] & PROPERTY_USAGE_EDITOR)
		for field in fields:
			var field_name: String = field["name"]
			if field_name.begins_with("_"):
				continue
			var property: AbstractProperty
			property = generate_property(field["type"], field)
			property.name = field_name.capitalize()
			property.set_meta("component_name", component.name)
			component_section.add_child(property)
		ui_root.add_child(component_section)
	$MarginContainer.add_child(ui_root)

	connect_ui(interactables, ui_root)
	load_properties.call_deferred(first_interactable, ui_root)


func generate_property(variant_type: int, field: Dictionary) -> AbstractProperty:
	var property: AbstractProperty
	match variant_type:
		TYPE_INT:
			if field["hint"] == PROPERTY_HINT_ENUM:
				property = EnumProperty.new()
				property.fields = field["hint_string"].split(",")
				for i in property.fields.size():
					property.fields.set(i, property.fields[i].get_slice(":", 0))
			else:
				property = FloatProperty.new()
				property.allow_lesser = true
				property.allow_greater = true
		TYPE_FLOAT:
			# TODO: get min, max, or_lesser and or_greater from hint_string
			property = FloatProperty.new()
			property.allow_lesser = true
			property.allow_greater = true
		TYPE_STRING:
			property = StringProperty.new()
		TYPE_COLOR:
			property = ColorProperty.new()
		TYPE_VECTOR2:
			property = Vector2Property.new()
		TYPE_BOOL:
			property = BoolProperty.new()
		TYPE_OBJECT:
			print_debug("TYPE_OBJECT")
			match field["hint"]:
				PROPERTY_HINT_NODE_TYPE:
					if field["hint_string"] == "Node2D":
						property = Node2DProperty.new()
		TYPE_ARRAY:
			property = ArrayProperty.new()
			var hint_string: String = field["hint_string"]
			var array_type := int(hint_string.get_slice("/", 0))
			var array_hint := int(hint_string.get_slice("/", 1))
			var array_hint_string: String = hint_string.get_slice(":", 1)
			var packed := PackedScene.new()
			# TODO: handle other typed arrays
			if array_type == TYPE_OBJECT and array_hint == PROPERTY_HINT_RESOURCE_TYPE:
				packed = load("res://scenes/components/game_components/resource_properties/" + array_hint_string + "Property.tscn")
			property.item_template = packed
	return property


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


func save_property(value: Variant, component_name: String, property: String, interactables: Array[Interactable]) -> void:
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
