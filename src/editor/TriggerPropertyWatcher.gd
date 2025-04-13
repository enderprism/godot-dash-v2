extends Node
class_name TriggerPropertyWatcher

@export var target: CanvasItem
## Comparison on the parent Property's value. Refer to the value as [value].
@export var condition: String
@export var property: StringName

func _ready() -> void:
	var parent := get_parent() as Property
	parent.value_changed.connect(_watcher_update_value)

func _watcher_update_value(value: Variant) -> void:
	var expression := Expression.new()
	expression.parse(condition, ["value"])
	var result := expression.execute([value]) as bool
	target.set(property, result)
	if target is Property:
		target.update_internals()
