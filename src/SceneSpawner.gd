extends Node

@export var scene: PackedScene
@export var amount: int

func _ready() -> void:
	for i in amount:
		var node: Node
		if scene.can_instantiate():
			node = scene.instantiate()
		else:
			node = Node.new()
		call_deferred("add_sibling", node)
	queue_free()
