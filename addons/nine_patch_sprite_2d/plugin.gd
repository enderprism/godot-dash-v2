@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("NinePatchSprite2D", "Node2D", preload("nine_patch_sprite_2d.gd"), preload("nine_patch_sprite_2d.svg"))


func _exit_tree():
	remove_custom_type("NinePatchSprite2D")
