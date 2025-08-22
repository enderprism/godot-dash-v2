extends Node
class_name Component

@onready var parent := get_parent() as Interactable


func _ready() -> void:
	parent.register_public(self)


func require(component_types: Array[Script]) -> void:
	for component_type in component_types:
		if not parent.has(component_type):
			push_warning("%s is missing %s" % [parent, component_type.get_global_name()])
			var component_instance: Component = component_type.new()
			parent.add_child(component_instance, true)
