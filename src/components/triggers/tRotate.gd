@tool
class_name tRotate extends tTriggerBase

@export var _target_group: Node2D
# @@buttons("Start Preview", _run(_target_group), "Stop Preview", _easer._cancel())
@export var _easing: tTriggerEasingRes
@export var _use_local_rotation: bool:
	get:
		if _use_target:
			return false
		else:
			return _use_local_rotation
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
@export var _rotation_target: Node2D
@export var _rotation_target_offset: Vector2 ## Offset in global coordinates from the move target.
@export_range(-360.0, 360.0, 0.01, "or_greater", "or_less") var _rotation_angle: float

func _validate_property(property: Dictionary) -> void:
	if property.name in ["_rotation_angle"] and _use_target:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_rotation_target", "_rotation_target_offset"] and not _use_target:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _trigger_type = "Rotate"
var _easer: tEasingSender = tEasingSender.new()
var _property: StringName:
	get:
		if not _use_local_rotation: return &"global_rotation_degrees"
		else: return &"rotation_degrees"

func _run(_body: Node2D) -> void:
	if _use_target:
		_easer._copy_target = _rotation_target
	_easer._final_value = _rotation_angle
	_easer._final_value_copy_target_offset = _rotation_target_offset
	_easer._start()

func _ready() -> void:
	_texture = preload("res://assets/textures/triggers/Rotate.svg")
	add_child(_easer)
	super()

func _physics_process(delta: float) -> void:
	super(delta)
	if Engine.is_editor_hint() and _easer != null:
		_easer._editor_preview()
