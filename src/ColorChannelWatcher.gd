extends Node
class_name ColorChannelWatcher

const WATCHER_GROUP_PREFIX := "watcher_"

var data: ColorChannelData


func _init(new_data: ColorChannelData) -> void:
	data = new_data
	add_to_group(WATCHER_GROUP_PREFIX + data.associated_group)
	data.changed.connect(refresh_objects_color)


func _ready() -> void:
	refresh_objects_color()


func refresh_objects_color(objects: Array = []) -> void:
	if objects.is_empty():
		objects = get_tree().get_nodes_in_group(data.associated_group)
	for object in objects:
		if object.has_node("SelectionHighlight"):
			object = object.get_node("SelectionHighlight")
		if data.copy:
			match data.copied_channel:
				ColorChannelData.CopyColor.BACKGROUND:
					object.modulate = LevelManager.background_sprites[0].modulate
				ColorChannelData.CopyColor.GROUND:
					object.modulate = LevelManager.ground_sprites[0].get_node("Ground").modulate
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
