extends Node
class_name ColorChannelWatcher

const WATCHER_GROUP_PREFIX := "watcher_"

var data: ColorChannelData


func _init(new_data: ColorChannelData) -> void:
	data = new_data
	add_to_group(WATCHER_GROUP_PREFIX + data.associated_group)
	data.changed.connect(refresh_objects_color)


func _exit_tree() -> void:
	if is_queued_for_deletion():
		data.set_color(Color.WHITE)
		data.set_copy(false)
		var hsv_shift_default: Array[float] = [0.0, 0.0, 0.0]
		data.set_hsv_shift(hsv_shift_default)
		refresh_objects_color()
		# Remove from group
		get_tree().get_nodes_in_group(data.associated_group).map(func(object): object.remove_from_group(data.associated_group))


func _ready() -> void:
	refresh_objects_color()


func refresh_objects_color(objects: Array = []) -> void:
	if objects.is_empty():
		objects = get_tree().get_nodes_in_group(data.associated_group)
	for object in objects:
		if object.has_node("HSVWatcher"):
			object = object.get_node("HSVWatcher")
		# If the object has an HSVWatcher, the SelectionHighlight will be parented to it to work correctly.
		if object.has_node("SelectionHighlight"):
			object = object.get_node("SelectionHighlight")
		if data.copy:
			match data.copied_channel:
				ColorChannelData.CopyColor.BACKGROUND:
					object.modulate = LevelManager.background_sprites[0].modulate
				ColorChannelData.CopyColor.GROUND:
					object.modulate = LevelManager.ground_sprites[0].get_node("Ground").self_modulate
				ColorChannelData.CopyColor.LINE:
					object.modulate = LevelManager.ground_sprites[0].get_node("Ground/Line").modulate
				ColorChannelData.CopyColor.P1:
					pass
				ColorChannelData.CopyColor.P2: 
					pass
				ColorChannelData.CopyColor.GLOW:
					pass
		else:
			object.modulate = data.color
		object.modulate.h += data.hsv_shift[0]
		object.modulate.s += data.hsv_shift[1]
		object.modulate.v += data.hsv_shift[2]
