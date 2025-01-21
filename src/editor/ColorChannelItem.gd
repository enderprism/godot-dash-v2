extends PanelContainer
class_name ColorChannelItem

const COLOR_PREVIEW_DISABLED := Color("#00000080")


signal selected
signal unselected

@export var channel_name: String

var data: ColorChannelData


func _ready() -> void:
	data = ColorChannelData.new()
	update()


func update() -> void:
	var channel_name_label := %ChannelName as Label
	channel_name_label.text = channel_name
	if not data.copy:
		_set_color_preview_color(data.color)._hide_color_preview_text()
	else:
		match data.copied_channel:
			ColorChannelData.CopyColor.BACKGROUND:
				_disable_color_preview()._show_color_preview_text("BG")
			ColorChannelData.CopyColor.GROUND:
				_disable_color_preview()._show_color_preview_text("G")
			ColorChannelData.CopyColor.LINE:
				_disable_color_preview()._show_color_preview_text("L")
			ColorChannelData.CopyColor.P1:
				_disable_color_preview()._show_color_preview_text("P1")
			ColorChannelData.CopyColor.P2:
				_disable_color_preview()._show_color_preview_text("P2")
			ColorChannelData.CopyColor.GLOW:
				_disable_color_preview()._show_color_preview_text("GL")


func _set_color_preview_color(_color: Color) -> ColorChannelItem:
	var color_preview := %ColorPreview as PanelContainer
	var color_preview_stylebox := color_preview.get_theme_stylebox("panel") as StyleBoxFlat
	color_preview_stylebox.bg_color = _color
	return self


func _disable_color_preview() -> ColorChannelItem:
	var color_preview := %ColorPreview as PanelContainer
	var color_preview_stylebox := color_preview.get_theme_stylebox("panel") as StyleBoxFlat
	color_preview_stylebox.bg_color = COLOR_PREVIEW_DISABLED
	return self


func _show_color_preview_text(text: String) -> ColorChannelItem:
	var color_preview_text := %ColorPreviewText as Label
	color_preview_text.show()
	color_preview_text.text = text
	return self


func _hide_color_preview_text() -> ColorChannelItem:
	var color_preview_text := %ColorPreviewText as Label
	color_preview_text.hide()
	return self


func _on_button_pressed() -> void:
	if $EditButton.button_pressed:
		unselected.emit()
	queue_free()


func _on_edit_button_toggled(toggled_on:bool) -> void:
	if toggled_on:
		selected.emit()
	else:
		unselected.emit()

