extends Area2D
class_name Interactable

signal interacted(body: Node2D)

var components: Array[Component]


func _ready() -> void:
	if LevelManager.in_editor:
		var editor_selection_collider := get_node_or_null("EditorSelectionCollider")
		if editor_selection_collider == null:
			editor_selection_collider = preload("res://scenes/components/level_components/EditorSelectionCollider.tscn").instantiate() as EditorSelectionCollider
			editor_selection_collider.type = EditorSelectionCollider.Type.INTERACTABLE
			add_child(editor_selection_collider)
			editor_selection_collider.set_owner(self)
	if has_node("Hitbox"):
		$Hitbox.debug_color = Color("00ff0033")


func register_public(component: Component) -> void:
	components.append(component)


func has(component_type: Script) -> bool:
	return components.any(func(component): return component.get_script() == component_type)
