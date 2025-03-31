extends PanelContainer
class_name TriggerEditor

const EASING_UI := preload(TriggerSetup.TRIGGER_UI_DIRECTORY + "trigger_components/TriggerEasingUI.tscn")
const TRIGGER_PROPERTY_GROUP := "trigger_property"
const TRIGGER_EASING_PROPERTY_GROUP := "trigger_easing_property"
const TRIGGER_BASE_PROPERTY_GROUP := "trigger_base_property"


func build_ui(trigger: TriggerBase) -> void:
	if not ResourceLoader.exists(trigger.ui_path, "PackedScene"):
		printerr("Trigger UI doesn't exist for path: ", trigger.ui_path)
		return
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
	connect_ui(trigger)
	load_property(trigger)

# TODO handle hiding properties depending on others (analog to _validate_property_list)

func connect_ui(trigger: TriggerBase) -> void:
	for group in [TRIGGER_PROPERTY_GROUP, TRIGGER_EASING_PROPERTY_GROUP, TRIGGER_BASE_PROPERTY_GROUP]:
		var properties := get_tree().get_nodes_in_group(group)
		if properties.is_empty():
			printerr("Empty properties in ", group)
			return
		var property_owner := trigger.get_parent() if group == TRIGGER_PROPERTY_GROUP else trigger.get_node("../TriggerEasing") if group == TRIGGER_EASING_PROPERTY_GROUP else trigger
		for property in properties as Array[Property]:
			if group == TRIGGER_BASE_PROPERTY_GROUP:
				match property.name:
					"Group":
						property.value_changed.connect(save_property.bind("target_group", property_owner))
					"Target":
						property.value_changed.connect(save_property.bind("_target", property_owner))
					_:
						property.value_changed.connect(save_property.bind(property.name.to_camel_case(), property_owner))
			elif group == TRIGGER_EASING_PROPERTY_GROUP:
				match property.name:
					"Duration":
						property.value_changed.connect(save_property.bind("_duration", property_owner))
						print_debug(property_owner._duration)
					"Easing":
						property.value_changed.connect(save_property.bind("easing_type", property_owner))
					"Transition":
						property.value_changed.connect(save_property.bind("easing_transition", property_owner))
			else:
				property.value_changed.connect(save_property.bind(property.name.to_camel_case(), property_owner))


func save_property(value: Variant, property: String, property_owner: Node) -> void:
	property_owner.set(property, value)


func load_property(trigger: TriggerBase) -> void:
	for group in [TRIGGER_PROPERTY_GROUP, TRIGGER_EASING_PROPERTY_GROUP, TRIGGER_BASE_PROPERTY_GROUP]:
		var properties := get_tree().get_nodes_in_group(group)
		if properties.is_empty():
			return
		var property_owner := trigger.get_parent() if group == TRIGGER_PROPERTY_GROUP else trigger.get_node("../TriggerEasing") if group == TRIGGER_EASING_PROPERTY_GROUP else trigger
		for property in properties as Array[Property]:
			var property_name := property.name.to_camel_case()
			if group == TRIGGER_BASE_PROPERTY_GROUP:
				match property.name:
					"Group":
						property_name = "target_group"
					"Target":
						property_name = "_target"
			elif group == TRIGGER_EASING_PROPERTY_GROUP:
				match property.name:
					"Duration":
						property_name = "_duration"
						print_debug("duration")
					"Easing":
						property_name = "easing_type"
					"Transition":
						property_name = "easing_transition"
			if property_owner.get(property_name) == null:
				printerr("Can't load_property property ", property_name, " on ", property_owner)
				continue
			property.set_value(property_owner.get(property_name), property.type)
