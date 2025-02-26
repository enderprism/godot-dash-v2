extends Node
class_name ColorChannelSetter

@export var base: Property
@export var detail: Property
@export var color_channel_editor: ColorChannelEditor


func _ready() -> void:
	base._input[Property.Type.STRING].focus_entered.connect(_on_property_focus_entered)
	detail._input[Property.Type.STRING].focus_entered.connect(_on_property_focus_entered)


func _on_property_focus_entered() -> void:
	if color_channel_editor.button_group.get_pressed_button():
		color_channel_editor.button_group.get_pressed_button().set_pressed(false)


func _on_base_color_value_changed(value:Variant) -> void:
	var base_channel := value as String
	var existing_color_channels := LevelManager.editor_edited_level.color_channels.map(func(channel): return channel.associated_group.lstrip(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX))
	if not base_channel in existing_color_channels:
		base.set_value("", Property.Type.STRING)
		return
	var objects_base: Array
	for object in $"../EditHandler".selection:
		objects_base.append(object.get_node("Base") if object.has_node("Base") else object)
	clear_color_channels(objects_base)
	if base_channel == "":
		objects_base.map(_reset_color)
		return
	objects_base.map(func(object): object.add_to_group(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + base_channel, true))
	var watcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + base_channel) as ColorChannelWatcher
	watcher.refresh_objects_color(objects_base)



func _on_detail_color_value_changed(value:Variant) -> void:
	var detail_channel := value as String
	var existing_color_channels := LevelManager.editor_edited_level.color_channels.map(func(channel): return channel.associated_group.lstrip(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX))
	if not detail_channel in existing_color_channels:
		detail.set_value("", Property.Type.STRING)
		return
	var objects_detail: Array = (
		$"../EditHandler".selection
			.map(func(object): return object.get_node_or_null("Detail") as Node2D)
			.filter(func(object): return object != null)
	)
	clear_color_channels(objects_detail)
	if detail_channel == "":
		objects_detail.map(_reset_color)
		return
	objects_detail.map(func(object): object.add_to_group(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + detail_channel, true))
	var watcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + detail_channel) as ColorChannelWatcher
	watcher.refresh_objects_color(objects_detail)
	

func clear_color_channels(selection: Array) -> void:
	for color_channel in LevelManager.editor_edited_level.color_channels:
		selection.map(func(object): object.remove_from_group(color_channel.associated_group))

func _on_edit_handler_selection_changed(selection:Array[Node2D]) -> void:
	if selection.is_empty():
		return
	# Base
	var objects_base: Array[Node2D]
	for object in selection:
		objects_base.append(object.get_node("Base") if object.has_node("Base") else object)
	var base_channel_array: Array = objects_base[-1].get_groups().filter(func(group): return ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX in group)
	var base_channel: String
	if not base_channel_array.is_empty():
		base_channel = base_channel_array[0]
	base_channel = base_channel.lstrip(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX)
	if base_channel != null or base_channel != "":
		base.set_value(base_channel, Property.Type.STRING)
	else:
		base.set_value("", Property.Type.STRING)
	# Detail
	var objects_detail: Array = (
		$"../EditHandler".selection
			.map(func(object): return object.get_node_or_null("Detail") as Node2D)
			.filter(func(object): return object != null)
	)
	if objects_detail.is_empty():
		return
	var detail_channel_array: Array = objects_detail[-1].get_groups().filter(func(group): return ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX in group)
	var detail_channel: String
	if not detail_channel_array.is_empty():
		detail_channel = detail_channel_array[0]
	detail_channel = detail_channel.lstrip(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX)
	if detail_channel != null or base_channel != "":
		detail.set_value(detail_channel, Property.Type.STRING)
	else:
		detail.set_value("", Property.Type.STRING)


func _reset_color(object: Node) -> void:
	if object.has_node("SelectionHighlight"):
		object = object.get_node("SelectionHighlight")
	object.modulate = Color.WHITE
