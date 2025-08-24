extends Node
class_name Component

@onready var parent := get_parent() as Interactable


func _ready() -> void:
	parent.register_public(self)


func require(component_types: Array[Script]) -> void:
	if not parent.is_node_ready():
		await parent.ready
	for component_type in component_types:
		assert(parent.has(component_type), "%s is missing %s" % [parent, component_type.get_global_name()])
