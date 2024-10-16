extends Area2D
class_name Interactable

@export var single_usage := false

var components: Array[Node]

func _ready() -> void:
	add_child(preload("res://scenes/components/level_components/EditorSelectionCollider.tscn").instantiate())
	if has_node("Hitbox"):
		$Hitbox.debug_color = Color("00ff0033")


func register_public(component: Node):
	components.append(component)
