# Copyright (c) 2024 NinStar
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the “Software”),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@tool
@icon("nine_patch_sprite_2d.svg")

class_name NinePatchSprite2D extends Node2D


## A Node2D that displays a texture by keeping its corners intact,
## but tiling its edges and center.
##
## Also known as 9-slice panels, [b]NinePatchSprite2D[/b] produces
## clean panels of any size based on a small texture.
## To do so, it splits the texture in a 3×3 grid.
## When you scale the node, it tiles the texture's edges horizontally or
## vertically, tiles the center on both axes, and leaves the corners unchanged.


## Emitted when the sprite changes size.
signal resized()


enum AxisStretchMode {
	## Stretches the center texture across the NinePatchSprite2D.
	## This may cause the texture to be distorted.
	AXIS_STRETCH_MODE_STRETCH,
	## Repeats the center texture across the NinePatchSprite2D.
	## This won't cause any visible distortion. The texture must be seamless
	## for this to work without displaying artifacts between edges.
	AXIS_STRETCH_MODE_TILE,
	## Repeats the center texture across the NinePatchSprite2D, but will also
	## stretch the texture to make sure each tile is visible in full. 
	## This may cause the texture to be distorted, but less than
	## [param AXIS_STRETCH_MODE_TILE_STRETCH]. The texture must be seamless
	## for this to work without displaying artifacts between edges.
	AXIS_STRETCH_MODE_TILE_FIT,
}


## [Texture2D] object to draw.
@export var texture: Texture2D: get = get_texture, set = set_texture

## The size of the sprite to be drawn.
@export var size := Vector2(0.0, 0.0): get = get_size, set = set_size

## If [code]true[/code], draw the sprite's center.
## Else, only draw 9-slice's borders.
@export var draw_center: bool = true: get = is_draw_center_enabled, set = set_draw_center

## Rectangular region of the texture to sample from.
## If you're working with an atlas, use this property to
## define the area the 9-slice should use.
## All other properties are relative to this one.
## If the rect is empty, NinePatchRect will use the whole texture.
@export var region_rect: Rect2: get = get_region_rect, set = set_region_rect

@export_group("Patch Margin", "patch_margin_")

## The width of the 9-slice's left column. A margin of 16 means the
## 9-slice's left corners and side will have a width of 16 pixels.
## You can set all 4 margin values individually to create
## panels with non-uniform borders.
@export var patch_margin_left: float = 0.0:
	set(value):
		patch_margin_left = value
		set_size(size)

## The width of the 9-slice's top column. A margin of 16 means the
## 9-slice's left corners and side will have a width of 16 pixels.
## You can set all 4 margin values individually to create
## panels with non-uniform borders.
@export var patch_margin_top: float = 0.0:
	set(value):
		patch_margin_top = value
		set_size(size)

## The width of the 9-slice's right column. A margin of 16 means the
## 9-slice's left corners and side will have a width of 16 pixels.
## You can set all 4 margin values individually to create
## panels with non-uniform borders.
@export var patch_margin_right: float = 0.0:
	set(value):
		patch_margin_right = value
		set_size(size)

## The width of the 9-slice's bottom column. A margin of 16 means the
## 9-slice's left corners and side will have a width of 16 pixels.
## You can set all 4 margin values individually to create
## panels with non-uniform borders.
@export var patch_margin_bottom: float = 0.0:
	set(value):
		patch_margin_bottom = value
		set_size(size)

@export_group("Axis Stretch", "axis_stretch_")

## The stretch mode to use for horizontal stretching/tiling.
## See [enum NinePatchSprite2D.AxisStretchMode] for possible values.
@export_enum("Stretch", "Tile", "Tile Fit") var axis_stretch_horizontal: int = 0: get = get_h_axis_stretch_mode, set = set_h_axis_stretch_mode

## The stretch mode to use for vertical stretching/tiling.
## See [enum NinePatchSprite2D.AxisStretchMode] for possible values.
@export_enum("Stretch", "Tile", "Tile Fit") var axis_stretch_vertical: int = 0: get = get_v_axis_stretch_mode, set = set_v_axis_stretch_mode

@export_group("Offset")

## If [code]true[/code], texture is centered.
@export var centered: bool = true: get = is_centered, set = set_centered

## The texture's drawing offset.
@export var offset := Vector2.ZERO: get = get_offset, set = set_offset

## If [code]true[/code], texture is flipped horizontally.
@export var flip_h: bool = false: get = is_flipped_h, set = set_flip_h

## If [code]true[/code], texture is flipped vertically.
@export var flip_v: bool = false: get = is_flipped_v, set = set_flip_v

@export_group("Animation")

## The number of columns in the sprite sheet.
@export var hframes: int = 1: get = get_hframes, set = set_hframes

## The number of rows in the sprite sheet.
@export var vframes: int = 1: get = get_vframes, set = set_vframes

## Current frame to display from sprite sheet.
## [member hframes] or [member vframes] must be greater than 1.
@export var frame: int = 0: get = get_frame, set = set_frame

## Coordinates of the frame to display from sprite sheet.
## This is as an alias for the [member frame] property.
## [member hframes] or [member vframes] must be greater than 1.
@export var frame_coords := Vector2i.ZERO: get = get_frame_coords, set = set_frame_coords


## Returns the size of the margin on the specified [enum @GlobalScope.Side].
func get_patch_margin(margin: Side) -> int:
	match margin:
		Side.SIDE_LEFT:
			return int(patch_margin_left)
		Side.SIDE_TOP:
			return int(patch_margin_top)
		Side.SIDE_RIGHT:
			return int(patch_margin_right)
		Side.SIDE_BOTTOM:
			return int(patch_margin_bottom)
		_:
			return 0


## Sets the size of the margin on the specified
## [enum @GlobalScope.Side] to value [code]pixels[/code].
func set_patch_margin(margin: Side, value: int) -> void:
	match margin:
		Side.SIDE_LEFT:
			patch_margin_left = float(value)
		Side.SIDE_TOP:
			patch_margin_top = float(value)
		Side.SIDE_RIGHT:
			patch_margin_right = float(value)
		Side.SIDE_BOTTOM:
			patch_margin_bottom = float(value)

#region Virtual methods

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAW:
			# Return if there is no texture to draw
			if texture == null:
				return
			
			# Get the canvas item of this node
			var canvas_item: RID = get_canvas_item()
			var trans := Transform2D.IDENTITY
			var from: Rect2 = region_rect
			var to := Rect2(Vector2.ZERO, size)
			
			# Frame
			from.position += from.size * Vector2(frame_coords)
			
			# Center the rectangle
			if centered:
				to.position -= size / 2.0
			if flip_h:
				# Flip transformation horizontally
				trans *= Transform2D.FLIP_X
				
				# Shift offset if it is centered
				if not centered:
					to.position.x -= size.x
			if flip_v:
				# Flip transformation vertically
				trans *= Transform2D.FLIP_Y
				
				# Shift offset if it is centered
				if not centered:
					to.position.y -= size.y
			
			# Apply offset to the rectangle's position accordingly to the transform
			to.position += offset * Vector2(signf(trans.x.x), signf(trans.y.y))
			
			# Apply transformation to the canvas item and draw a nine patch on it
			RenderingServer.canvas_item_add_set_transform(canvas_item, trans)
			RenderingServer.canvas_item_add_nine_patch(canvas_item,
					to, from, texture.get_rid(), 
					Vector2(patch_margin_left, patch_margin_top),
					Vector2(patch_margin_right, patch_margin_bottom),
					axis_stretch_horizontal, axis_stretch_vertical, draw_center)

#endregion
#region Getters & Setters

# Getters

func get_texture() -> Texture2D:
	return texture


func get_size() -> Vector2:
	return size


func is_draw_center_enabled() -> bool:
	return draw_center


func get_region_rect() -> Rect2:
	return region_rect


func get_h_axis_stretch_mode() -> AxisStretchMode:
	return axis_stretch_horizontal as AxisStretchMode


func get_v_axis_stretch_mode() -> AxisStretchMode:
	return axis_stretch_vertical as AxisStretchMode


func is_centered() -> bool:
	return centered


func get_offset() -> Vector2:
	return offset


func is_flipped_h() -> bool:
	return flip_h


func is_flipped_v() -> bool:
	return flip_v


func get_hframes() -> int:
	return hframes


func get_vframes() -> int:
	return vframes


func get_frame() -> int:
	return frame


func get_frame_coords() -> Vector2i:
	return frame_coords

# Setters

func set_texture(value: Texture2D) -> void:
	texture = value
	queue_redraw()


func set_size(value: Vector2) -> void:
	var current_size: Vector2 = size
	size.x = maxf(patch_margin_left+patch_margin_right, value.x)
	size.y = maxf(patch_margin_top+patch_margin_bottom, value.y)
	queue_redraw()
	if current_size != size:
		resized.emit()


func set_draw_center(value: bool) -> void:
	draw_center = value
	queue_redraw()


func set_region_rect(value: Rect2) -> void:
	region_rect = value
	queue_redraw()


func set_h_axis_stretch_mode(value: AxisStretchMode) -> void:
	axis_stretch_horizontal = value
	queue_redraw()


func set_v_axis_stretch_mode(value: AxisStretchMode) -> void:
	axis_stretch_vertical = value
	queue_redraw()


func set_centered(value: bool) -> void:
	centered = value
	queue_redraw()


func set_offset(value: Vector2) -> void:
	offset = value
	queue_redraw()


func set_flip_h(value: bool) -> void:
	flip_h = value
	queue_redraw()


func set_flip_v(value: bool) -> void:
	flip_v = value
	queue_redraw()


func set_hframes(value: int) -> void:
	hframes = maxi(1, value)
	if frame > hframes + vframes - 1:
		set_frame(frame)
	else:
		queue_redraw()


func set_vframes(value: int) -> void:
	vframes = maxi(1, value)
	if frame > hframes + vframes - 1:
		set_frame(frame)
	else:
		queue_redraw()


func set_frame(value: int) -> void:
	frame = clampi(value, 0, hframes * vframes - 1)
	var as_vec := Vector2i(frame % hframes, ceili(frame/hframes))
	if frame_coords != as_vec:
		set_frame_coords(as_vec)
	else:
		queue_redraw()


func set_frame_coords(value: Vector2i) -> void:
	frame_coords = value.clamp(Vector2i.ZERO, Vector2i(hframes-1, vframes-1))
	var as_int: int = frame_coords.x + (frame_coords.y * hframes)
	if frame != as_int:
		set_frame(as_int)
	else:
		queue_redraw()

#endregion
