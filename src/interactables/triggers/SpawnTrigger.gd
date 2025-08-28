@tool
extends Node2D
class_name SpawnTrigger

enum LoopState {
	DISABLED,
	COUNT,
	INFINITE,
}

# TODO in editor, refresh timer duration if a spawned group's duration is changed
@export var spawned_groups: Array[SpawnedGroup]:
	set(value):
		spawned_groups = value
		if is_node_ready():
			update_target_link()
@export var loop: LoopState = LoopState.DISABLED:
	set(value):
		loop = value
		notify_property_list_changed()
@export var loop_count: int = 1
@export_range(0.0, 10.0, 0.01, "or_greater", "suffix:s") var loop_delay: float = 0.0

# Debugging purposes only
@export_tool_button("Refresh Target Link") var refresh_target_link = update_target_link
@export_tool_button("Clear External Target Links") var clear_external_target_links = func(): 
		for group in spawned_groups:
			LevelManager.current_level.get_node(group.path).get_node("SpawnTargetLink").queue_free()

func _validate_property(property: Dictionary) -> void:
	if property.name in ["loop_count", "loop_delay"] and loop == LoopState.DISABLED:
		property.usage = PROPERTY_USAGE_NO_EDITOR


var base: TriggerBase
var easing: EasingComponent
var target_link: TargetLink

var _player: Player:
	get(): return LevelManager.player if not Engine.is_editor_hint() else null
var _current_loop: int
var _duration: float

func _ready() -> void:
	TriggerSetup.setup(self, TriggerSetup.ADD_TARGET_LINK | TriggerSetup.ADD_EASING)
	var skip_deleted := func(group):
		var spawned_trigger = LevelManager.current_level.get_node_or_null(group.path)
		if spawned_trigger == null:
			return false
		return not spawned_trigger.is_in_group("deleted")
	spawned_groups = spawned_groups.filter(skip_deleted)
	for group in spawned_groups:
		if group.time > _duration:
			_duration = group.time
	easing.duration = _duration
	base.sprite.set_texture(preload("res://assets/textures/triggers/Spawn.svg"))
	target_link = preload("res://scenes/components/game_components/TargetLink.tscn").instantiate()
	target_link.default_color = Color.CYAN
	set_meta(&"editor_update_target_link", "spawned_groups")
	update_target_link()

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not easing.is_inactive():
		if spawned_groups != null:
			var elapsed_time: float = _duration * easing.weights
			for group in spawned_groups:
				if (elapsed_time > group.time or is_equal_approx(elapsed_time, group.time)) and group.loop_idx != _current_loop:
					if LevelManager.current_level.get_node(group.path).has_node("TriggerBase"):
						LevelManager.current_level.get_node(group.path).base.emit_signal("body_entered", _player)
					group.loop_idx = _current_loop
		elif LevelManager.in_editor and LevelManager.level_playing:
			printerr("In ", name, ": there aren't any groups to spawn.")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		target_link.position = Vector2.ZERO
		if len(spawned_groups) >= 1 and spawned_groups[0].is_connected("changed", update_target_link):
			spawned_groups[0].changed.connect(update_target_link)
		if spawned_groups.is_empty(): target_link.target = null
		if Engine.is_editor_hint(): base.position = Vector2.ZERO

func start(_body: Node2D):
	if loop != LoopState.DISABLED and not easing.finished.is_connected(restart):
		easing.finished.connect(restart)
	_current_loop += 1

func restart() -> void:
	await get_tree().create_timer(loop_delay).timeout
	if loop == LoopState.INFINITE or _current_loop < loop_count:
		base.body_entered.emit(_player)

func update_target_link() -> void:
	if len(spawned_groups) >= 1:
		target_link.target = LevelManager.current_level.get_node_or_null(spawned_groups[0].path)
	if len(spawned_groups) >= 2:
		for i in range(len(spawned_groups)-1):
			# Start loop at index 1, skipping the first spawned group since it already has a 'spawn' target link
			var group = LevelManager.current_level.get_node_or_null(spawned_groups[i].path)
			if group == null:
				continue
			if not group.has_node("SpawnTargetLink"):
				var group_spawn_target_link: TargetLink = preload("res://scenes/components/game_components/TargetLink.tscn").instantiate()
				group_spawn_target_link.default_color = Color.CYAN
				group_spawn_target_link.name = "SpawnTargetLink"
				group_spawn_target_link.z_index -= 1
				group_spawn_target_link.target = LevelManager.current_level.get_node_or_null(spawned_groups[i+1].path)
				group.add_child(group_spawn_target_link)
				group_spawn_target_link.owner = group.get_parent()
			else:
				group.get_node("SpawnTargetLink").target = LevelManager.current_level.get_node_or_null(spawned_groups[i+1].path)
