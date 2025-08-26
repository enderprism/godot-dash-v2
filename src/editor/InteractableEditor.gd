extends Control
class_name InteractableEditor

# Scripts aren't constants but the array shouldn't be modified nontheless.
var COMPONENT_BLACKLIST: Array[Script] = [
	JumpBoostComponent,
	GravityChangerComponent,
	ReboundComponent,
	SpiderDashComponent,
	FireDashComponent,
	SpeedChangerComponent,
	# PlayerCountChangerComponent, # we need to be able to set if duals use the same gravity
	PlayerScaleChangerComponent,
	TextureRotationPin,
]

# Querying this at runtime is overkill
var MARKER_COMPONENTS: Array[Script] = [
	SingleUsageComponent,
	NoEffectsComponent,
]

var marker_properties: Dictionary[Script, BoolProperty]


func _init() -> void:
	COMPONENT_BLACKLIST.make_read_only()
	MARKER_COMPONENTS.make_read_only()


func _ready() -> void:
	for marker in MARKER_COMPONENTS:
		var property := BoolProperty.new()
		property.name = marker.get_global_name().trim_suffix("Component").capitalize()
		marker_properties.set(marker, property)
		%MarkerRoot.add_child(property)


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	clear_ui()
	if selection.is_empty() or not selection.all(is_interactable):
		return
	var interactables: Array[Interactable]
	interactables.assign(selection)
	build_ui(interactables)


func clear_ui() -> void:
	%ComponentRoot.get_children().map(func(child): child.queue_free())


func rebuild_ui(interactables: Array[Interactable]) -> void:
	clear_ui()
	build_ui(interactables)


func build_ui(interactables: Array[Interactable]) -> void:
	var first_interactable := interactables[0]
	var ui_root := VBoxContainer.new()
	for i in first_interactable.components.size():
		var component = first_interactable.components[i]
		NodeUtils.connect_once(component.property_list_changed, rebuild_ui)
		if component.get_script() in COMPONENT_BLACKLIST \
				or component.get_script() in MARKER_COMPONENTS:
			continue
		var fields = component.script.get_script_property_list()
		# Follow _validate_property
		if component.has_method(&"_validate_property"):
			fields.map(func(field): component._validate_property(field))
		fields = fields \
				.filter(func(field): return field.usage & PROPERTY_USAGE_EDITOR)
		for field in fields:
			var field_name: String = field.name
			if field_name.begins_with("_"):
				continue
			var property: AbstractProperty
			property = generate_property(field.type, field)
			property.name = field_name.capitalize()
			property.set_meta("component_name", component.name)
			property.set_input_state.call_deferred(not field.usage & PROPERTY_USAGE_READ_ONLY)
			ui_root.add_child(property)
		if i != first_interactable.components.size() - 1:
			ui_root.add_child(HSeparator.new())
	%ComponentRoot.add_child(ui_root)
	%ComponentRoot.visible = ui_root.get_child_count() > 0

	connect_ui(interactables, self)
	load_properties.call_deferred(first_interactable, self)


func generate_property(variant_type: int, field: Dictionary) -> AbstractProperty:
	var property: AbstractProperty
	match variant_type:
		TYPE_INT:
			if field["hint"] == PROPERTY_HINT_ENUM:
				property = EnumProperty.new()
				property.fields = field.hint_string.split(",")
				for i in property.fields.size():
					property.fields.set(i, property.fields[i].get_slice(":", 0))
			else:
				property = FloatProperty.new()
				property.allow_lesser = true
				property.allow_greater = true
				property.rounded = true
				property.step = 1.0
		TYPE_FLOAT:
			property = FloatProperty.new()
			if field.hint == PROPERTY_HINT_NONE:
				property.allow_lesser = true
				property.allow_greater = true
			elif field.hint == PROPERTY_HINT_RANGE:
				var hint_string: String = field.hint_string
				var min_value = hint_string.get_slice(",", 0)
				var max_value = hint_string.get_slice(",", 1)
				var step = hint_string.get_slice(",", 2)
				property.min_value = min_value
				property.max_value = max_value
				property.step = step
				if "or_greater" in hint_string:
					property.allow_greater = true
				if "or_less" in hint_string:
					property.allow_lesser = true
		TYPE_STRING, TYPE_STRING_NAME:
			property = StringProperty.new()
		TYPE_COLOR:
			property = ColorProperty.new()
		TYPE_VECTOR2:
			property = Vector2Property.new()
		TYPE_BOOL:
			property = BoolProperty.new()
		TYPE_OBJECT:
			match field.hint:
				PROPERTY_HINT_NODE_TYPE:
					if field.hint_string == "Node2D":
						property = Node2DProperty.new()
		TYPE_ARRAY:
			property = ArrayProperty.new()
			var hint_string: String = field.hint_string
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
		if property is BoolProperty and property in marker_properties.values():
			property.value_changed.connect(refresh_marker.bind(marker_properties.find_key(property), interactables))
			continue
		property.value_changed.connect(save_property.bind(property.get_meta("component_name"), property_name, interactables))


func save_property(value: Variant, component_name: String, property: String, interactables: Array[Interactable]) -> void:
	interactables.map(func(interactable):
		if interactable.get_node(component_name) is TargetGroupComponent:
			value = GroupEditor.GROUP_PREFIX + value
		interactable.get_node(component_name).set(property, value))


func refresh_marker(enabled: bool, marker_script: Script, interactables: Array[Interactable]) -> void:
	for interactable in	interactables:
		if enabled:
			var marker: Component = NodeUtils.get_node_or_add(interactable, str(marker_script.get_global_name()), marker_script, NodeUtils.SET_OWNER | NodeUtils.FORCE_READABLE_NAME)
			interactable.register_public(marker)
		else:
			NodeUtils.get_children_of_type(interactable, marker_script).map(func(marker):
				interactable.components.erase(marker)
				marker.queue_free())


func load_properties(interactable: Interactable, ui_root: Control) -> void:
	var properties := NodeUtils.get_children_of_type(ui_root, AbstractProperty, true)
	if properties.is_empty():
		return
	for property in properties as Array[AbstractProperty]:
		if property is BoolProperty and property in marker_properties.values():
			property.set_value_no_signal(interactable.has(marker_properties.find_key(property)))
			continue
		var property_name := property.name.to_snake_case()
		var component := interactable.get_node(String(property.get_meta("component_name")))
		if component == null or component.get(property_name) == null:
			printerr("Can't load property ", property_name, " on ", interactable)
			continue
		var value = component.get(property_name)
		if component is TargetGroupComponent:
			value = value.trim_prefix(GroupEditor.GROUP_PREFIX)
		property.set_value_no_signal(value)


static func is_interactable(object: Node2D) -> bool:
	return object is Interactable


static func is_trigger(object: Node2D) -> bool:
	return object is TriggerBase


static func same_script(object: Interactable, reference: Interactable) -> bool:
	return object.get_script() == reference.get_script()


static func same_components(object: Interactable, reference: Interactable) -> bool:
	return object.components == reference.components
