extends Node
class_name ColorChannelSetter


func _on_base_color_value_changed(value:Variant) -> void:
	var base_channel := value as String
	var objects_base: Array[Node2D] = (
		$"../EditHandler".selection
			.map(func(object): return object.get_node_or_null("Base") as Node2D)
			.filter(func(object): return object != null)
	)
	if objects_base.is_empty():
		objects_base = $"../EditHandler".selection
	clear_color_channels(objects_base)
	objects_base.map(func(object): object.add_to_group(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + base_channel))



func _on_detail_color_value_changed(value:Variant) -> void:
	var detail_channel := value as String
	var objects_detail: Array[Node2D] = (
		$"../EditHandler".selection
			.map(func(object): return object.get_node_or_null("Detail") as Node2D)
			.filter(func(object): return object != null)
	)
	clear_color_channels(objects_detail)
	objects_detail.map(func(object): object.add_to_group(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + detail_channel))
	


func clear_color_channels(selection: Array[Node2D]) -> void:
	for color_channel in LevelManager.editor_edited_level.color_channels:
		selection.map(func(object): object.remove_from_group(color_channel.associated_group))
