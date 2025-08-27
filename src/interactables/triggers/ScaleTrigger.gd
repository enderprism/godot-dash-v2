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

@export var mode: Mode = Mode.MULTIPLY:
	set(value):
		mode = value
		notify_property_list_changed()
@export var scale_around_self: bool:
	set(value):
		scale_around_self = value
		notify_property_list_changed()
@export var pivot: Node2D
@export var change_position_only: bool
@export var target_scale: Vector2 = Vector2.ONE
@export var copy_target: Node2D
@export var copy_multiplier: Vector2 = Vector2.ONE ## Multiplier of the scale of the copy target.

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name in ["copy_target", "copy_multiplier"] and mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["pivot", "change_position_only"] and scale_around_self:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _targets: Array[Node] ## Array of all the [Node2D] in a group.
var _initial_scales: Dictionary ## Scale for every [Node2D] in [member _targets]
var base: TriggerBase
var easing: EasingComponent
var target_link: TargetLink

func _ready() -> void:
	TriggerSetup.setup(self, TriggerSetup.ADD_TARGET_LINK | TriggerSetup.ADD_EASING)
	base.sprite.set_texture(preload("res://assets/textures/triggers/Scale.svg"))

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not easing.is_inactive():
		if not _targets.is_empty():
			var _pivot_scale: Vector2
			# Do assignment outside loop to avoid doing for every object in the group.
			# The performance benefit is probably negligeable.
			if not scale_around_self:
				_pivot_scale = pivot.global_scale
			for _target: Node2D in _targets:
				var _initial_global_scale: Vector2 = _initial_scales[_target]
				var _scale_delta: Vector2
				match mode:
					Mode.SET:
						_scale_delta = (target_scale - _initial_global_scale) * easing.weight_delta
					Mode.ADD:
						_scale_delta = target_scale * easing.weight_delta
					Mode.MULTIPLY:
						_scale_delta = ((_initial_global_scale * target_scale) - _initial_global_scale) * easing.weight_delta
					Mode.DIVIDE:
						_scale_delta = ((_initial_global_scale / target_scale) - _initial_global_scale) * easing.weight_delta
					Mode.COPY:
						if copy_target != null:
							_target.global_scale = lerp(_initial_global_scale, copy_target.global_scale * copy_multiplier, easing.weight)
						elif LevelManager.in_editor and LevelManager.level_playing:
							printerr("In ", name, ": copy_target is unset!")
						# Escape the current loop iteration to avoid adding the rotation delta, even if it's null.
						continue
				if scale_around_self:
					_target.global_scale += _scale_delta
				else:
					var position_relative_to_pivot: Vector2 = _target.global_position - pivot.global_position
					var position_delta := position_relative_to_pivot * ((_target.global_scale + _scale_delta) / _target.global_scale) - position_relative_to_pivot
					_target.global_position += position_delta
					if not change_position_only:
						_target.global_scale += _scale_delta
		elif LevelManager.in_editor and LevelManager.level_playing:
			printerr("In ", name, "_process: _target is unset")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		target_link.position = Vector2.ZERO
		if Engine.is_editor_hint(): base.position = Vector2.ZERO

func update_target_link() -> void:
	target_link.target = base._target

func start(_body: Node2D) -> void:
	_targets = get_tree().get_nodes_in_group(base.target_group)
	if pivot == null and not scale_around_self:
		# Toasts.new_toast("Error: in %s: pivot is unset" % name, 1.0, Toasts.ERROR)
		easing.tween.kill()
	if easing.is_inactive():
		if not _targets.is_empty():
			for _target: Node2D in _targets:
				_initial_scales[_target] = _target.global_scale
		# elif LevelManager.in_editor and LevelManager.level_playing:
		# 	Toasts.new_toast("Error: in %s: trigger has no target group" % name, 1.0, Toasts.ERROR)

func reset() -> void:
	if not _targets.is_empty():
		for _target in _targets:
			_target.global_scale = _initial_scales[_target]
	elif LevelManager.in_editor and LevelManager.level_playing:
		printerr("In ", name, ", reset: _target is unset")
