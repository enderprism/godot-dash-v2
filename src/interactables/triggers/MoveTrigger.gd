@tool
extends Node2D
class_name MoveTrigger

enum Mode {
	ADD,
	SET,
	MOVE_TOWARDS,
}


@export var mode: Mode = Mode.ADD:
	set(value):
		mode = value
		notify_property_list_changed()
@export var _position: Vector2 ## New position in units.
@export_group("Move Towards", "_move_towards")
@export var _move_towards_target: Node2D
## Multiplies the target distance between each object in the group. [br][br]
## [b]Examples:[/b] [br]
##   •  [code]0.0[/code]: the group's objects will all move towards the target object. [br]
##   •  [code]1.0[/code]: the group's objects will follow the target object but [b]keep[/b] their relative distance to it. [br]
##   •  [code]2.0[/code]: the group's objects will follow the target object but [b]double[/b] their relative distance to it. [br]
##   •  [code]-1.0[/code]: the group's objects will follow the target object but [b]invert[/b] their relative distance to it.
@export var _move_towards_group_center: Node2D
@export_range(0.0, 2.0, 0.05, "or_greater", "or_less") var _move_towards_distance_multiplier: float = 1.0
@export var _move_towards_offset: Vector2 ## Offset in global coordinates in units from the move target.

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_add_position" and mode != Mode.ADD:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_set_position" and mode != Mode.SET:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_move_towards_target", "_move_towards_group_center", "_move_towards_offset", "_move_towards_distance_multiplier"] and mode != Mode.MOVE_TOWARDS:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var base: TriggerBase
var easing: TriggerEasing
var target_link: TargetLink

var CELLS_TO_PX := Vector2(LevelManager.CELL_SIZE, -LevelManager.CELL_SIZE)

var _targets: Array[Node]
var _initial_positions: Dictionary
var _initial_distances: Dictionary

func _ready() -> void:
	TriggerSetup.setup(self, TriggerSetup.ADD_TARGET_LINK | TriggerSetup.ADD_EASING)
	base.sprite.set_texture(preload("res://assets/textures/triggers/Move.svg"))

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not easing.is_inactive():
		if not _targets.is_empty():
			for _target in _targets:
				var _initial_global_position = _initial_positions[_target]
				match mode:
					Mode.SET:
						_target.global_position += (owner.to_global(_position * CELLS_TO_PX) - _initial_global_position) * easing.weight_delta
					Mode.ADD:
						_target.global_position += _position * easing.weight_delta * CELLS_TO_PX
					Mode.MOVE_TOWARDS:
						var _initial_distance = _initial_distances[_target]
						if _move_towards_target != null:
							_target.global_position = lerp(
									_initial_global_position,
									_move_towards_target.global_position + (_initial_distance * _move_towards_distance_multiplier) + _move_towards_offset * CELLS_TO_PX,
									easing.weight)
						elif LevelManager.in_editor and LevelManager.level_playing:
							printerr("In ", name, ": move_towards_target is unset!")
		elif LevelManager.in_editor and LevelManager.level_playing:
			printerr("In ", name, ": _target is unset")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		target_link.position = Vector2.ZERO
		if Engine.is_editor_hint(): base.position = Vector2.ZERO

func update_target_link() -> void:
	target_link.target = _targets[0]

func start(_body: Node2D) -> void:
	_targets = get_tree().get_nodes_in_group(base.target_group)
	if easing.is_inactive():
		if not _targets.is_empty():
			for _target in _targets:
				_initial_positions[_target] = _target.global_position
				if mode == Mode.MOVE_TOWARDS:
					_initial_distances[_target] = _move_towards_target.global_position - _target.global_position
		elif LevelManager.in_editor and LevelManager.level_playing:
			printerr("In ", name, ": base._target is unset")

func reset() -> void:
	if not _targets.is_empty():
		for _target in _targets:
			_target.global_position = _initial_positions[_target]
	elif LevelManager.in_editor and LevelManager.level_playing:
		printerr("In ", name, ": _target is unset")
