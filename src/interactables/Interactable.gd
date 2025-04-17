extends Area2D
class_name Interactable

@export var single_usage: bool:
	set(value):
		single_usage = value
		if value:
			NodeUtils.get_node_or_add(self, "SingleUsageComponent", SingleUsageComponent)
		elif get_node_or_null(^"SingleUsageComponent") != null:
			get_node(^"SingleUsageComponent").queue_free()

var components: Array[Node]

func _ready() -> void:
	if LevelManager.in_editor:
		var editor_selection_collider := preload("res://scenes/components/level_components/EditorSelectionCollider.tscn").instantiate() as EditorSelectionCollider
		editor_selection_collider.type = EditorSelectionCollider.Type.INTERACTABLE
		add_child(editor_selection_collider)
		editor_selection_collider.set_owner(self)
	if has_node("Hitbox"):
		$Hitbox.debug_color = Color("00ff0033")


func register_public(component: Node):
	components.append(component)
