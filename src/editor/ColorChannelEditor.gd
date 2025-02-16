extends PanelContainer

@export var button_group: ButtonGroup
@export var separator: HSeparator
@export var properties_container: VBoxContainer
@onready var color_channel_item := preload("res://scenes/components/game_components/ColorChannelItem.tscn")


func _ready() -> void:
	%Channel.setup_enum(PackedStringArray([
		"Background",
		"Ground",
		"Line",
		"P1",
		"P2",
		"Glow",
	]))

func _on_button_pressed() -> void:
	_add_channel(%LineEdit.get_text())
	%LineEdit.clear()

func _on_line_edit_text_submitted(new_text:String) -> void:
	_add_channel(new_text)
	%LineEdit.clear()


func _add_channel(channel_name: String) -> void:
	if (channel_name in %ColorChannelContainer.get_children()
			.map(func(color_channel: ColorChannelItem): return color_channel.channel_name)):
		return
	var channel_item := color_channel_item.instantiate() as ColorChannelItem
	channel_item.channel_name = channel_name
	channel_item.selected.connect(_show_properties)
	channel_item.unselected.connect(_hide_properties)
	channel_item.update()
	channel_item.register()
	%ColorChannelContainer.add_child(channel_item)

func _hide_properties() -> void:
	separator.hide()
	properties_container.hide()

func _show_properties() -> void:
	separator.show()
	properties_container.show()
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	%"Copy channel".set_value(channel_item.data.copy, Property.Type.BOOL)
	%Channel.set_value(channel_item.data.copied_channel, Property.Type.ENUM)
	%Color.set_value(channel_item.data.color, Property.Type.COLOR)
	%"HSV shift".set_value(channel_item.data.hsv_shift, Property.Type.COLOR)
	%Channel.visible = channel_item.data.copy
	%Color.visible = not channel_item.data.copy

func _on_color_value_changed(value:Variant) -> void:
	var new_color := value as Color
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	channel_item.data.set_color(new_color)
	channel_item.update()

func _on_copy_channel_value_changed(value:Variant) -> void:
	var copy_channel := value as bool
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	channel_item.data.set_copy(copy_channel)
	channel_item.update()
	%Color.visible = not copy_channel
	%Channel.visible = copy_channel


func _on_channel_value_changed(value:Variant) -> void:
	var new_channel := value as ColorChannelData.CopyColor
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	channel_item.data.set_copied_channel(new_channel)
	channel_item.update()
	

func _on_hsv_shift_value_changed(value:Variant) -> void:
	var new_hsv_shift := value as Color
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	channel_item.data.set_hsv_shift(new_hsv_shift)
	channel_item.update()

