extends Object
class_name NodeUtils

const INTERNAL := 1 << 0
const SET_OWNER := 1 << 1
const FORCE_READABLE_NAME := 1 << 2


# Note: passing a value for the type parameter causes a crash
static func get_child_of_type(node: Node, child_type):
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		if is_instance_of(child, child_type):
			return child


# Note: passing a value for the type parameter causes a crash
static func get_children_of_type(node: Node, child_type):
	var list = []
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		if is_instance_of(child, child_type):
			list.append(child)
	return list


static func set_child_owner(caller: Node, child: Node) -> void:
	var _owner: Node = caller.get_parent() if caller.get_parent().get_owner() == null else caller.get_parent().get_owner()
	child.set_owner(_owner)

## Return a reference to a node. If it doesn't exist, create it.
## Options:
##   - INTERNAL
##   - SET_OWNER
##   - FORCE_READABLE_NAME
static func get_node_or_add(caller: Node, path: NodePath, script, options: int = SET_OWNER) -> Node:
	var node := caller.get_node_or_null(path)
	if node == null:
		node = script.new()
		node.name = str(path)
		caller.add_child(node, options & FORCE_READABLE_NAME == FORCE_READABLE_NAME, options & INTERNAL)
		if options & SET_OWNER:
			set_child_owner(caller, node)
	return node


static func connect_new(_signal: Signal, callable: Callable) -> void:
	if not _signal.is_connected(callable):
		_signal.connect(callable)
