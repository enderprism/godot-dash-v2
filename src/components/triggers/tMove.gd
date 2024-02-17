@tool
class_name tMove extends tTriggerBase

@export var _target_group: Node2D
# @@buttons("Start Preview", _run(_target_group), "Stop Preview", _easer._cancel())
@export var _easing: tTriggerEasingRes
@export var _use_local_coordinates: bool:
	get:
		if _use_target:
			return false
		else:
			return _use_local_coordinates
@export var _relative: bool:
	get:
		if _use_target:
			return true
		else:
			return _relative
@export var _use_target: bool:
	set(value):
		_use_target = value
		if not value:
			_easer._copy_target = null
		notify_property_list_changed()
@export var _move_target: Node2D
@export var _move_target_offset: Vector2 ## Offset in global coordinates from the move target.
@export var _move_coordinates: Vector2

func _validate_property(property: Dictionary) -> void:
	if property.name in ["_move_coordinates"] and _use_target:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_move_target", "_move_target_offset"] and not _use_target:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _trigger_type = "Move"
var _easer: tPropertyInterpolator = tPropertyInterpolator.new()
var _property: StringName:
	get:
		if not _use_local_coordinates: return &"global_position"
		else: return &"position"

func _run(_body: Node2D) -> void:
	if _use_target:
		_easer._copy_target = _move_target
	_easer._final_value = _move_coordinates
	_easer._final_value_copy_target_offset = _move_target_offset
	_easer._start()

func _ready() -> void:
	_texture = preload("res://assets/textures/triggers/Move.svg")
	add_child(_easer)
	super()

func _physics_process(delta: float) -> void:
	super(delta)
	if Engine.is_editor_hint() and _easer != null:
		_easer._editor_preview()
