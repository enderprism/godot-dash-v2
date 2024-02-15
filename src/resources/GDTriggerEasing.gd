@tool class_name GDTriggerEasing extends Resource

@export_range(0.0, 5.0, 0.01, "or_greater") var _tween_duration: float = 1.0

@export var _use_custom_easing: bool:
	set(value):
		_use_custom_easing = value
		notify_property_list_changed()

@export var _tween_transition: Tween.TransitionType

@export var _tween_easing: Tween.EaseType = Tween.EASE_IN_OUT

@export var _custom_easing: Curve

func _validate_property(property: Dictionary) -> void:
	if property.name in ["_tween_easing", "_tween_transition"] and _use_custom_easing:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_custom_easing"] and not _use_custom_easing:
		property.usage = PROPERTY_USAGE_NO_EDITOR