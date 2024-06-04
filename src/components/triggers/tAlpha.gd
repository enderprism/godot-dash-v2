@tool
extends Node2D
class_name tAlpha

enum Mode {
	SET,
	MULTIPLY,
	DIVIDE,
	COPY,
}

@export var _mode: Mode = Mode.SET:
	set(value):
		_mode = value
		notify_property_list_changed()
@export_range(0.0, 1.0, 0.01) var _alpha: float
@export var _copy_target: Node2D
@export_range(0.0, 1.0, 0.01, "or_greater") var _copy_multiplier: float

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_set_alpha" and _mode == Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_copy_target", "_copy_multiplier"] and _mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _targets: Array[Node] ## Array of all the [Node2D] in a group.
var _initial_alphas: Dictionary
var _base: tBase
var _easing: tEasing
var _target_link: GDTargetLink

func _ready() -> void:
	TriggerSetup.setup(self, true)
	_base._sprite.set_texture(preload("res://assets/textures/triggers/Alpha.svg"))
	_targets = get_tree().get_nodes_in_group(_base._target_group)

func _update_target_link() -> void:
	_target_link._target = _base._target

func _start(_body: Node2D) -> void:
	if _easing._is_inactive():
		if not _targets.is_empty():
			for _target: Node2D in _targets:
				_initial_alphas[_target] = _target.modulate.a
		else:
			printerr("In ", name, ": _target is unset")

func _reset() -> void:
	if not _targets.is_empty():
		for _target: Node2D in _targets:
			_target.modulate.a = _initial_alphas[_target]
	else:
		printerr("In ", name, ": _target is unset")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(_easing._weight):
		if not _targets.is_empty():
			var _weight_delta = _easing._get_weight_delta()
			for _target: Node2D in _targets:
				var _initial_alpha: float = _initial_alphas[_target]
				match _mode:
					Mode.SET:
						_target.modulate.a += (_alpha - _initial_alpha) * _weight_delta
					Mode.MULTIPLY:
						_target.modulate.a += (_alpha * _initial_alpha - _initial_alpha) * _weight_delta
					Mode.COPY:
						if _copy_target != null:
							_target.modulate.a = lerp(_initial_alpha, _copy_target.modulate.a * _copy_multiplier, _easing._weight)
						else:
							printerr("In ", name, ": copy_target is unset!")
		else:
			printerr("In ", name, ": _target is unset")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		_target_link.position = Vector2.ZERO
		if Engine.is_editor_hint(): _base.position = Vector2.ZERO
