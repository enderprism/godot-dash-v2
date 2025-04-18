@tool
extends Node

@export var button_group: ButtonGroup
@export var type: EditorSelectionCollider.Type
@export var object: PackedScene
@export var textures: Array[TextureOverride]

@export_tool_button("Generate Buttons") var _generate_buttons = generate_buttons

@onready var parent := get_parent()

func generate_buttons() -> void:
	var clear_children := func(child): if child is BouncyButton: child.queue_free()
	parent.get_children().map(clear_children)
	for i in range(len(textures)):
		var texture := textures[i]
		texture.name = texture.base.resource_path.get_file().get_basename().trim_suffix("Base")
		# Button
		var button := BouncyButton.new()
		button.block_palette_button = true
		button.custom_minimum_size = Vector2.ONE * 64.0
		button.set_meta("texture_override", texture)
		button.set_meta("_edit_group_", true)
		button.name = texture.name
		button.toggle_mode = true
		button.button_group = button_group
		parent.add_child(button)
		button.owner = parent.owner
		# Ref
		var block_palette_ref := BlockPaletteRef.new()
		block_palette_ref.type = type
		block_palette_ref.id = i
		block_palette_ref.object = object
		button.add_child(block_palette_ref)
		block_palette_ref.owner = parent.owner
		# Display
		var texture_rects: Array[TextureRect]
		var base := TextureRect.new()
		base.texture = texture.base
		texture_rects.append(base)
		if texture.detail != null:
			var detail := TextureRect.new()
			detail.texture = texture.detail
			texture_rects.append(detail)
		for texture_rect in texture_rects:
			texture_rect.expand_mode = TextureRect.ExpandMode.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.size = button.size
			button.add_child(texture_rect)
			texture_rect.owner = parent.owner
