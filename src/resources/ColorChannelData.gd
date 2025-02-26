extends Resource
class_name ColorChannelData


enum CopyColor {
	BACKGROUND,
	GROUND,
	LINE,
	# TODO implement players colors
	P1,
	P2,
	GLOW,
}

@export var copy: bool
@export var color: Color
@export var copied_channel: CopyColor
@export var hsv_shift: Array[float] = [0.0, 0.0, 0.0]
@export var associated_group: String


func set_copy(should_copy: bool = false) -> ColorChannelData:
	copy = should_copy
	changed.emit()
	return self

func set_color(new_color: Color) -> ColorChannelData:
	color = new_color
	changed.emit()
	return self

func set_copied_channel(new_copied_channel: CopyColor) -> ColorChannelData:
	copied_channel = new_copied_channel
	changed.emit()
	return self

func set_hsv_shift(new_hsv_shift: Array[float]) -> ColorChannelData:
	hsv_shift = new_hsv_shift
	changed.emit()
	return self
