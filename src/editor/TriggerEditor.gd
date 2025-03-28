extends PanelContainer
class_name TriggerEditor

const EASING_UI := preload(TriggerSetup.TRIGGER_UI_DIRECTORY + "trigger_components/TriggerEasingUI.tscn")

func build_ui(trigger: TriggerBase) -> void:
	if not ResourceLoader.exists(trigger.ui_path, "PackedScene"):
		printerr("Trigger UI doesn't exist for path: ", trigger.ui_path)
		return
	var ui := load(trigger.ui_path) as PackedScene
	if %UIRoot.get_child(0) != null:
		%UIRoot.get_child(0).queue_free()
	%UIRoot.add_child(ui.instantiate())
	if not trigger.has_node("../TriggerEasing"):
		%UIRoot.get_node("Tweening").queue_free()
	if trigger.has_node("../TriggerEasing") and %UIRoot.get_node("Tweening") == null:
		var trigger_easing_ui := EASING_UI.instantiate() as SectionHeading
		%UIRoot.add_child(trigger_easing_ui, true, INTERNAL_MODE_BACK)
		trigger_easing_ui.set_deferred("name", "Tweening")

# TODO handle loading and saving values to triggers
# TODO handle hiding properties depending on others (analog to _validate_property_list)
