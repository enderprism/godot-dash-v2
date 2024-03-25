@tool 
class_name tEasingReciever extends Node

var _property: StringName
var _delta_value: Variant
var _active_senders: Array[tEasingSender]

func _physics_process(_delta: float) -> void:
	# _delta_value = null
	# for _active_sender in _active_senders:
	# 	var _sender_delta = _active_sender._get_delta_value()
	# 	if not is_zero_approx(_active_sender._lerp_weight) and _sender_delta != null:
	# 		if _delta_value == null:
	# 			_delta_value = _sender_delta
	# 		else:
	# 			_delta_value += _sender_delta
	# if _delta_value != null:
	# 	get_parent().set(_property, get_parent().get(_property) + _delta_value)
	for _active_sender in _active_senders:
		get_parent().set(_property, get_parent().get(_property) + _active_sender._get_delta_value())
