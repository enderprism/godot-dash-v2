@tool class_name tEasingSender extends Node
## Interpolates a given property of a target to a value using a
## trigger easing resource.

var _parent_trigger_type
var _reciever: tEasingReciever
## Duration, easing type and transition or custom easing curve for the interpolation.
var _easing: tTriggerEasingRes
var _lerp_tween: Tween
var _lerp_weight: float
var _target: Node2D
var _copy_target: Node2D
var _property: StringName
var _relative: bool
var _initial_value: Variant = null
var _final_value: Variant = null
var _final_value_lock: Variant = null
var _final_value_copy_target_offset: Variant = null

func _get_final_value() -> Variant:
	if _target != null:
		if _copy_target != null:
			return _copy_target.get(_property) + _final_value_copy_target_offset
		elif _final_value_lock == null:
			if _relative:
				_final_value_lock = _final_value + _target.get(_property)
				return _final_value_lock
			else:
				_final_value_lock = _final_value
				return _final_value_lock
		else:
			return _final_value_lock
	else: return null

func _start_lerp_tween() -> void:
	_lerp_tween = get_parent().create_tween()
	if not _easing._use_custom_easing:
		_lerp_tween.tween_property(self, "_lerp_weight", 1.0, _easing._tween_duration) \
			.set_ease(_easing._tween_easing) \
			.set_trans(_easing._tween_transition) \
			.from(0.0)
	elif _easing._custom_easing != null:
		_lerp_tween.tween_property(self, "_lerp_weight", 1.0, _easing._tween_duration).from(0.0)

func _get_lerp_weight() -> float:
	if not _easing._use_custom_easing:
		return _lerp_weight
	elif _easing._custom_easing != null:
		return _easing._custom_easing.sample(_lerp_weight)
	else:
		return 0.0

## Start a [tPropertysender]. Only one [tPropertysender] can run at a time, and the running one is prioritary, so wait until it's done to start a new one.
func _start() -> void:
	if "_trigger_type" in get_parent():
		_parent_trigger_type = get_parent()._trigger_type
	_easing = get_parent()._easing
	_target = get_parent()._target_group
	_property = get_parent()._property
	if &"_relative" in get_parent():
		_relative = get_parent()._relative
	if is_zero_approx(_lerp_weight):
		_initial_value = _target.get(_property)
		_start_lerp_tween()
	if not _target.has_node("EasingReciever"):
		_reciever = tEasingReciever.new()
		_reciever.name = "EasingReciever"
		_reciever._property = _property
		_target.add_child(_reciever)
	else:
		_reciever = _target.get_node("EasingReciever")
	if not self in _reciever._active_senders:
		_reciever._active_senders.append(self)

## Cancel the running interpolation.
func _cancel() -> void:
	if _lerp_tween != null:
		_lerp_tween.kill()
	_lerp_weight = 0.0
	if _initial_value != null:
		_target.set(_property, _initial_value)
		_initial_value = null
	_final_value_lock = null

var _previous_value
var _current_value

func _get_delta_value() -> Variant:
	if _initial_value != null:
		var _delta_value
		_current_value = lerp(_initial_value, _get_final_value(), _get_lerp_weight())
		if _previous_value != null:
			_delta_value = _current_value - _previous_value
		_previous_value = _current_value
		return _delta_value
	else: return null

## Automatically cancel the tPropertysender when it's done interpolating (only runs in the editor, see [method Engine.is_editor_hint]).
func _editor_preview() -> void:
	if _lerp_weight == 1.0:
		_cancel()
