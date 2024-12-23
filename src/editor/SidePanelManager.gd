class_name SidePanelManager
extends Node


@export var tree: Tree


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var root = tree.create_item()
	tree.hide_root = true
	var child1 = tree.create_item(root)
	child1.set_text(0, "Group")
	var child2 = tree.create_item(root)
	var subchild1 = tree.create_item(child1)
	subchild1.set_cell_mode(0, TreeItem.CELL_MODE_RANGE)
	subchild1.set_range(0, 10.0)
	subchild1.set_editable(0, true)
	subchild1.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	subchild1.set_text(1, "Subchild1")
