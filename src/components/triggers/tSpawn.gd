@tool
class_name tSpawn extends tTriggerBase

@export var _easing: tTriggerEasingRes
@export var _spawned_groups: Array[gSpawnedGroup]
@export var _loop: bool = false:
	set(value):
		_loop = value
		notify_property_list_changed()
@export var _loop_count: int = 1
@export var _loop_delay: float = 0.0

func _validate_property(property: Dictionary) -> void:
	if property.name in ["_loop_count", "_loop_delay"] and not _loop:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _easer: tEasingSender = tEasingSender.new()
var _target_group = self
var _trigger_type = "Spawn"
var _property: StringName = "_time"

var _time: float
var _loop_count_tracker: int

func _run(_body: Node2D):
	if _loop_count > 0 and _loop_count_tracker == 0: _loop_count_tracker = _loop_count
	_easer._final_value = 1.0
	_easer._start()

func _ready() -> void:
	_texture = preload("res://assets/textures/triggers/Spawn.svg")
	add_child(_easer)
	super()

func _physics_process(delta: float) -> void:
	super(delta)
	if _easer._lerp_weight > 0.0:
		for _group in _spawned_groups:
			if _time >= _group.time and not _group.used:
				get_node(_group.path)._run(self)
				_group.used = true
	if not Engine.is_editor_hint():
		print_debug(_time," ", _loop_count_tracker)
	if _loop and (_loop_count_tracker > 0 or _loop_count < 0) and _time >= 1.0:
		_time = 0.0
		if _loop_delay > 0.0: await get_tree().create_timer(_loop_delay).timeout
		_easer._start()
		print_debug("restarting")
		if _loop_count_tracker > 0:
			_loop_count_tracker -= 1

