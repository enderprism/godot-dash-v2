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

## Initialise the groups required to use ITC on the caller.
static func init(caller: Node) -> void:
	caller.add_to_group(
		caller._base._target_group + "-triggers" + TriggerType.keys()[caller.TRIGGER_TYPE].to_lower()
	)

## Connect all the triggers of a type to the caller.
static func bridge(caller: Node, type: TriggerType, trigger_signal: StringName, caller_method: Callable) -> void:
	var group: StringName = caller._base._target_group + "-triggers" + TriggerType.keys()[type].to_lower()
	var objects: Array[Node] = caller.get_tree().get_nodes_in_group(group)
	for object in objects:
		print(object.get_parent())
		object.connect(trigger_signal, caller_method)

## TODO Disconnect all the triggers of a type from the caller and deinit the caller.

## Set the parent trigger's data in the target's ITC metadata
## @deprecated
static func set_data(caller: Node, target: Node, data: Variant) -> void:
	var metadata_string: String = TriggerType.keys()[caller.TRIGGER_TYPE].to_lower() + "_triggers"
	if target.has_meta(metadata_string):
		var target_trigger_metadata: Dictionary = target.get_meta(metadata_string)
		if not caller in target_trigger_metadata:
			target_trigger_metadata[caller.get_path()] = data
			target.set_meta(metadata_string, target_trigger_metadata)
	else:
		target.set_meta(metadata_string, {caller.get_path(): data})

## Returns the data of all triggers of a certain type of the target's ITC metadata
## @deprectated
static func get_data(target: Node, type: TriggerType) -> Dictionary:
	var metadata_string: String = TriggerType.keys()[type].to_lower() + "_triggers"
	if target.has_meta(metadata_string):
		var metadata: Dictionary = target.get_meta(metadata_string)
		return metadata
	else:
		return {}

## Returns the sum of the data of all triggers of a certain type of the target's ITC metadata
## @deprectated
static func get_data_sum(target: Node, type: TriggerType) -> Variant:
	var metadata_string: String = TriggerType.keys()[type].to_lower() + "_triggers"
	if target.has_meta(metadata_string):
		var metadata: Dictionary = target.get_meta(metadata_string)
		if metadata.is_empty(): return null
		return metadata.values().reduce(func(accum, number): return accum + number)
	else:
		return null
