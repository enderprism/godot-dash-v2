@tool
extends Node2D
class_name AlphaTrigger

enum Mode {
	SET,
	MULTIPLY,
	DIVIDE,
	COPY,
}

@export var mode: Mode = Mode.SET:
	set(value):
		mode = value
		notify_property_list_changed()
@export_range(0.0, 1.0, 0.01) var alpha: float
@export var copy_target: Node2D
@export_range(0.0, 1.0, 0.01, "or_greater") var copy_multiplier: float

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_set_alpha" and mode == Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["copy_target", "copy_multiplier"] and mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR


var base: TriggerBase
var easing: TriggerEasing
var target_link: TargetLink

var _targets: Array[Node] ## Array of all the [Node2D] in a group.
var _initial_alphas: Dictionary

func _ready() -> void:
	TriggerSetup.setup(self, true)
	base.sprite.set_texture(preload("res://assets/textures/triggers/Alpha.svg"))
	_targets = get_tree().get_nodes_in_group(base.target_group)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(easing._weight):
		if not _targets.is_empty():
			var _weight_delta = easing._get_weight_delta()
			for _target: Node2D in _targets:
				var _initial_alpha: float = _initial_alphas[_target]
				match mode:
					Mode.SET:
						_target.modulate.a += (alpha - _initial_alpha) * _weight_delta
					Mode.MULTIPLY:
						_target.modulate.a += (alpha * _initial_alpha - _initial_alpha) * _weight_delta
					Mode.COPY:
						if copy_target != null:
							_target.modulate.a = lerp(_initial_alpha, copy_target.modulate.a * copy_multiplier, easing._weight)
						elif LevelManager.in_editor and LevelManager.level_playing:
							printerr("In ", name, ": copy_target is unset!")
		elif LevelManager.in_editor and LevelManager.level_playing:
			printerr("In ", name, ": _target is unset! ")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		target_link.position = Vector2.ZERO
		if Engine.is_editor_hint(): base.position = Vector2.ZERO


func update_target_link() -> void:
	target_link.target = base._target

func start(_body: Node2D) -> void:
	if easing._is_inactive():
		if not _targets.is_empty():
			for _target: Node2D in _targets:
				_initial_alphas[_target] = _target.modulate.a
		elif LevelManager.in_editor and LevelManager.level_playing:
			printerr("In ", name, ": _target is unset")

func reset() -> void:
	if not _targets.is_empty():
		for _target: Node2D in _targets:
			_target.modulate.a = _initial_alphas[_target]
	elif LevelManager.in_editor and LevelManager.level_playing:
		printerr("In ", name, ": _target is unset")