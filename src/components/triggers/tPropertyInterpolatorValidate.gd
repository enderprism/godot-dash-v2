@tool class_name tPropertyInterpolatorValidate extends Node

var _property: StringName
var _delta_value: Variant
var _active_interpolators: Array[tPropertyInterpolator]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	_delta_value = null
	for _active_interpolator in _active_interpolators:
		var _interpolator_delta = _active_interpolator._get_delta_value()
		if not is_zero_approx(_active_interpolator._lerp_weight) and _interpolator_delta != null:
			if _delta_value == null:
				_delta_value = _interpolator_delta
			else:
				_delta_value += _interpolator_delta
	if _delta_value != null:
		get_parent().set(_property, get_parent().get(_property) + _delta_value)
