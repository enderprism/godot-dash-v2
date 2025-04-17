extends Area2D
class_name Interactable

@export var single_usage := false

var components: Array[Component]

func _ready() -> void:
	if LevelManager.in_editor:
		var editor_selection_collider := preload("res://scenes/components/level_components/EditorSelectionCollider.tscn").instantiate() as EditorSelectionCollider
		editor_selection_collider.type = EditorSelectionCollider.Type.INTERACTABLE
		add_child(editor_selection_collider)
		editor_selection_collider.set_owner(self)
	if has_node("Hitbox"):
		$Hitbox.debug_color = Color("00ff0033")


func register_public(component: Component):
	components.append(component)
