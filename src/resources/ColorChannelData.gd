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
@export var hsv_shift: Color

func set_copy(should_copy: bool = false) -> ColorChannelData:
	copy = should_copy
	return self

func set_color(new_color: Color) -> ColorChannelData:
	color = new_color
	return self

func set_copied_channel(new_copied_channel: CopyColor) -> ColorChannelData:
	copied_channel = new_copied_channel
	return self
