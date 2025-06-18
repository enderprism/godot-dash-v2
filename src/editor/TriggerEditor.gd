extends PanelContainer
class_name TriggerEditor

const EASING_UI := preload(TriggerSetup.TRIGGER_UI_DIRECTORY + "trigger_components/TriggerEasingUI.tscn")
const TRIGGER_PROPERTY_GROUP := "trigger_property"
const TRIGGER_EASING_PROPERTY_GROUP := "trigger_easing_property"
const TRIGGER_BASE_PROPERTY_GROUP := "trigger_base_property"


func build_ui(triggers: Array[TriggerBase]) -> void:
	var trigger := triggers[0]
	if not ResourceLoader.exists(trigger.ui_path, "PackedScene"):
		printerr("Trigger UI doesn't exist for path: ", trigger.ui_path)
		hide()
		return
	else:
		show()
	var ui := load(trigger.ui_path) as PackedScene
	var instanced_ui := ui.instantiate()
	if %UIRoot.get_child(0) != null:
		%UIRoot.get_child(0).queue_free()
	%UIRoot.add_child(instanced_ui)
	if not trigger.has_node("../TriggerEasing"):
		%UIRoot.get_node("Tweening").queue_free()
	if trigger.has_node("../TriggerEasing") and %UIRoot.get_node("Tweening") == null:
		var trigger_easing_ui := EASING_UI.instantiate() as SectionHeading
		%UIRoot.add_child(trigger_easing_ui, true, INTERNAL_MODE_BACK)
		trigger_easing_ui.set_deferred("name", "Tweening")
	connect_ui(triggers)
	call_deferred("load_properties", trigger)


func connect_ui(triggers: Array[TriggerBase]) -> void:
	for group in [TRIGGER_PROPERTY_GROUP, TRIGGER_EASING_PROPERTY_GROUP, TRIGGER_BASE_PROPERTY_GROUP]:
		var properties := get_tree().get_nodes_in_group(group)
		if properties.is_empty():
			printerr("Empty properties in ", group)
			return
		for property in properties as Array[AbstractProperty]:
			var remove_connections := func(connection):
				if not "watcher" in connection.callable.get_method():
					property.value_changed.disconnect(connection.callable)
			property.value_changed.get_connections().map(remove_connections)
			var property_name := property.name.to_camel_case()
			if property.has_node("TriggerPropertyInternalName"):
				property_name = property.get_node("TriggerPropertyInternalName").property_name
			property.value_changed.connect(save_property.bind(property_name, triggers, group))


func save_property(value: Variant, property: String, triggers: Array, group: String) -> void:
	if property == "target_group":
		value = GroupEditor.GROUP_PREFIX + value
	var to_property_owner := func(trigger):
		var property_owner: Node = trigger.get_parent() if group == TRIGGER_PROPERTY_GROUP else trigger.get_node("../TriggerEasing") if group == TRIGGER_EASING_PROPERTY_GROUP else trigger
		return property_owner
	var property_owners := triggers.map(to_property_owner)
	property_owners.map(func(property_owner): property_owner.set(property, value))


func load_properties(trigger: TriggerBase) -> void:
	for group in [TRIGGER_PROPERTY_GROUP, TRIGGER_EASING_PROPERTY_GROUP, TRIGGER_BASE_PROPERTY_GROUP]:
		var properties := get_tree().get_nodes_in_group(group)
		if properties.is_empty():
			return
		var property_owner := trigger.get_parent() if group == TRIGGER_PROPERTY_GROUP else trigger.get_node("../TriggerEasing") if group == TRIGGER_EASING_PROPERTY_GROUP else trigger
		for property in properties as Array[AbstractProperty]:
			var property_name := property.name.to_camel_case()
			if property.has_node("TriggerPropertyInternalName"):
				property_name = property.get_node("TriggerPropertyInternalName").property_name
			if property_owner.get(property_name) == null:
				printerr("Can't load_property property ", property_name, " on ", property_owner)
				continue
			var value = property_owner.get(property_name)
			if property_name == "target_group":
				value = value as String
				value = value.trim_prefix(GroupEditor.GROUP_PREFIX)
			var refresh_watchers := func(property_child): property_child.call_deferred("_watcher_update_value", value)
			var watchers: Array = NodeUtils.get_children_of_type(property, PropertyWatcher)
			watchers.map(refresh_watchers)
			property.set_value_no_signal(value)
