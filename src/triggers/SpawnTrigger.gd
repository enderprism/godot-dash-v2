@tool
extends Node2D
class_name SpawnTrigger

@export var _spawned_groups: Array[SpawnedGroup]
@export var _loop: bool = false:
	set(value):
		_loop = value
		notify_property_list_changed()
@export var _loop_count: int = 1
@export_range(0.0, 10.0, 0.01, "or_greater", "suffix:s") var _loop_delay: float = 0.0

# Debugging purposes only
@export var _refresh_target_link: bool:
	set(value):
		update_target_link()
@export var _clear_external_target_links: bool:
	set(value):
		for _group in _spawned_groups:
			get_node(_group.path).get_node("SpawnTargetLink").queue_free()


func _validate_property(property: Dictionary) -> void:
	if property.name in ["_loop_count", "_loop_delay"] and not _loop:
		property.usage = PROPERTY_USAGE_NO_EDITOR


var base: TriggerBase
var easing: TriggerEasing
var target_link: TargetLink

var _player: Player:
	get(): return LevelManager.player if not Engine.is_editor_hint() else null
var _current_loop: int

func _ready() -> void:
	TriggerSetup.setup(self, true)
	base.sprite.set_texture(preload("res://assets/textures/triggers/Spawn.svg"))
	target_link.default_color = Color.CYAN
	update_target_link()

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(easing._weight):
		if _spawned_groups != null:
			for _group in _spawned_groups:
				if easing._weight >= _group.time and _group.used_in_loop != _current_loop:
					if get_node(_group.path).has_node("TriggerBase"): get_node(_group.path).base.emit_signal("body_entered", _player)
					_group.used_in_loop = _current_loop
		else:
			printerr("In ", name, ": _target is unset")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		target_link.position = Vector2.ZERO
		if len(_spawned_groups) >= 1 and _spawned_groups[0].is_connected("changed", update_target_link):
			_spawned_groups[0].changed.connect(update_target_link)
		if _spawned_groups.is_empty(): target_link.target = null
		if Engine.is_editor_hint(): base.position = Vector2.ZERO

func start(_body: Node2D):
	if _loop and not easing._tween.is_connected("finished", restart):
		easing._tween.finished.connect(restart)
	_current_loop += 1

func restart() -> void:
	await get_tree().create_timer(_loop_delay).timeout
	if _loop_count < 0 or _current_loop < _loop_count:
		base.emit_signal("body_entered", _player)

func update_target_link() -> void:
	if len(_spawned_groups) >= 1:
		target_link.target = get_node_or_null(_spawned_groups[0].path)
	if len(_spawned_groups) >= 2:
		for i in range(len(_spawned_groups)-1):
			# Start loop at index 1, skipping the first spawned group since it already has a 'spawn' target link
			var _group = get_node(_spawned_groups[i].path)
			if not _group.has_node("SpawnTargetLink"):
				var _group_spawn_target_link: TargetLink = load("res://scenes/components/game_components/TargetLink.tscn").instantiate()
				_group_spawn_target_link.default_color = Color.CYAN
				_group_spawn_target_link.name = "SpawnTargetLink"
				_group_spawn_target_link.z_index -= 1
				_group_spawn_target_link._target = get_node_or_null(_spawned_groups[i+1].path)
				_group.add_child(_group_spawn_target_link)
				_group_spawn_target_link.owner = _group.get_parent()
			else:
				_group.get_node("SpawnTargetLink")._target = get_node_or_null(_spawned_groups[i+1].path)