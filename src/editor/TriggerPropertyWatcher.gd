extends Node
class_name TriggerPropertyWatcher

@export var target: CanvasItem
## Comparison on the parent Property's value. Refer to the value as [value].
@export var condition: String
@export var property: StringName
@export var if_false: String
@export var if_true: String

func _ready() -> void:
	var parent := get_parent() as Property
	parent.value_changed.connect(_watcher_update_value)

func _watcher_update_value(value: Variant) -> void:
	var expression := Expression.new()
	expression.parse(condition, ["value"])
	var result := expression.execute([value]) as bool
	if result:
		expression.parse(if_true)
	else:
		expression.parse(if_false)
	target.set(property, expression.execute())
	if target is Property:
		target.update_internals()
