extends Node
class_name ITC
## Helper class containing boilerplate code
## to use ITC (inter-trigger communication).

enum TriggerType {
	ALPHA,
	CAMERA_OFFSET,
	CAMERA_ROTATE,
	CAMERA_STATIC,
	CAMERA_ZOOM,
	GAMEPLAY_ROTATE,
	GRAVITY,
	MOVE,
	ROTATE,
	SCALE,
	SONG,
	SPAWN,
	TIMEWARP,
	TOGGLE,
}

## Set the parent trigger's data in the target's ITC metadata
static func set_data(_parent: Node, _target: Node, _data: Variant) -> void:
	var _metadata_string: String = TriggerType.keys()[_parent.TRIGGER_TYPE].to_lower() + "_triggers"
	if _target.has_meta(_metadata_string):
		var _target_trigger_metadata: Dictionary = _target.get_meta(_metadata_string)
		if not _parent in _target_trigger_metadata:
			_target_trigger_metadata[_parent.get_path()] = _data
			_target.set_meta(_metadata_string, _target_trigger_metadata)
	else:
		_target.set_meta(_metadata_string, {_parent.get_path(): _data})

## Returns the data of all triggers of a certain type of the target's ITC metadata
static func get_data(_parent: Node, _target: Node, _type: TriggerType) -> Dictionary:
	var _metadata_string: String = TriggerType.keys()[_type].to_lower() + "_triggers"
	if _target.has_meta(_metadata_string):
		var _metadata: Dictionary = _target.get_meta(_metadata_string)
		return _metadata
	else:
		return {}

## Returns the sum of the data of all triggers of a certain type of the target's ITC metadata
static func get_data_sum(_parent: Node, _target: Node, _type: TriggerType) -> Variant:
	var _metadata_string: String = TriggerType.keys()[_type].to_lower() + "_triggers"
	if _target.has_meta(_metadata_string):
		var _metadata: Dictionary = _target.get_meta(_metadata_string)
		if _metadata.is_empty(): return null
		return _metadata.values().reduce(func(accum, number): return accum + number)
	else:
		return null
