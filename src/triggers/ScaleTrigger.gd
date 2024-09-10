@tool
extends Node2D
class_name ScaleTrigger

enum Mode {
	ADD,
	MULTIPLY,
	DIVIDE,
	SET,
	COPY,
}

@export var _scale_around_self: bool:
	set(value):
		_scale_around_self = value
		notify_property_list_changed()
@export var _pivot: Node2D
@export var _change_position_only: bool
@export var mode: Mode = Mode.ADD:
	set(value):
		mode = value
		notify_property_list_changed()
@export var _set_scale: Vector2
@export var _add_scale: Vector2
@export var _multiply_scale: Vector2
@export var _copy_target: Node2D
@export var _copy_multiplier: Vector2 = Vector2.ONE ## Multiplier of the scale of the copy target.

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_set_scale" and mode != Mode.SET:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_add_scale" and mode != Mode.ADD:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_multiply_scale" and mode != Mode.MULTIPLY and mode != Mode.DIVIDE:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_copy_target", "_copy_multiplier"] and mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_pivot", "_change_position_only"] and _scale_around_self:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _targets: Array[Node] ## Array of all the [Node2D] in a group.
var _initial_scales: Dictionary ## Scale for every [Node2D] in [member _targets]
var base: TriggerBase
var easing: TriggerEasing
var target_link: TargetLink

func _ready() -> void:
	TriggerSetup.setup(self, true)
	base.sprite.set_texture(preload("res://assets/textures/triggers/Scale.svg"))
	_targets = get_tree().get_nodes_in_group(base.target_group)

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(easing._weight):
		if not _targets.is_empty():
			var _weight_delta = easing._get_weight_delta()
			var _pivot_scale: Vector2
			# Do assignment outside loop to avoid doing for every object in the group.
			# The performance benefit is probably negligeable.
			if not _scale_around_self:
				_pivot_scale = _pivot.global_scale
			for _target: Node2D in _targets:
				var _initial_global_scale: Vector2 = _initial_scales[_target]
				var _scale_delta: Vector2
				match mode:
					Mode.SET:
						_scale_delta = (_set_scale - _initial_global_scale) * _weight_delta
					Mode.ADD:
						_scale_delta = _add_scale * _weight_delta
					Mode.MULTIPLY:
						_scale_delta = ((_initial_global_scale * _multiply_scale) - _initial_global_scale) * _weight_delta
					Mode.DIVIDE:
						_scale_delta = ((_initial_global_scale / _multiply_scale) - _initial_global_scale) * _weight_delta
					Mode.COPY:
						if _copy_target != null:
							_target.global_scale = lerp(_initial_global_scale, _copy_target.global_scale * _copy_multiplier, easing._weight)
						else:
							printerr("In ", name, ": copy_target is unset!")
						# Escape the current loop iteration to avoid adding the rotation delta, even if it's null.
						continue
				if _scale_around_self:
					_target.global_scale += _scale_delta
				else:
					var _target_parent: Node = _target.get_parent()
					_pivot.global_scale = _initial_global_scale
					_target.reparent(_pivot)
					_pivot.global_scale += _scale_delta
					_target.reparent(_target_parent)
					_pivot.global_scale = _pivot_scale
					if _change_position_only:
						_target.global_scale = _initial_global_scale
		else:
			printerr("In ", name, "_process: _target is unset")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		target_link.position = Vector2.ZERO
		if Engine.is_editor_hint(): base.position = Vector2.ZERO

func update_target_link() -> void:
	target_link.target = base._target

func start(_body: Node2D) -> void:
	if easing._is_inactive():
		if not _targets.is_empty():
			for _target: Node2D in _targets:
				_initial_scales[_target] = _target.global_scale
		else:
			printerr("In ", name, ", start: _target is unset")

func reset() -> void:
	if not _targets.is_empty():
		for _target in _targets:
			_target.global_scale = _initial_scales[_target]
	else:
		printerr("In ", name, ", reset: _target is unset")