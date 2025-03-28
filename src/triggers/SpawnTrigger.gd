@tool
extends Node2D
class_name SpawnTrigger

# TODO in editor, refresh timer duration if a spawned group's duration is changed
@export var spawned_groups: Array[SpawnedGroup]
@export var loop: bool = false:
	set(value):
		loop = value
		notify_property_list_changed()
@export var loop_count: int = 1
@export_range(0.0, 10.0, 0.01, "or_greater", "suffix:s") var loop_delay: float = 0.0

# Debugging purposes only
@export var refresh_target_link: bool:
	set(value):
		update_target_link()
@export var clear_external_target_links: bool:
	set(value):
		for group in spawned_groups:
			get_node(group.path).get_node("SpawnTargetLink").queue_free()


func _validate_property(property: Dictionary) -> void:
	if property.name in ["loop_count", "loop_delay"] and not loop:
		property.usage = PROPERTY_USAGE_NO_EDITOR


var base: TriggerBase
var timer: Timer
var target_link: TargetLink

var _player: Player:
	get(): return LevelManager.player if not Engine.is_editor_hint() else null
var _current_loop: int

func _ready() -> void:
	TriggerSetup.setup(self, TriggerSetup.ADD_TARGET_LINK)
	timer = NodeUtils.get_node_or_add(self, "Timer", Timer)
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	timer.one_shot = true # We need one_shot to be on to have a custom loop delay.
	var duration := 0.0
	for group in spawned_groups:
		if group.time > duration:
			duration = group.time
	# Spawn triggers with durations of 0 will get a timer wait time of 1.0, but it doesn't really matter.
	timer.wait_time = duration
	base.sprite.set_texture(preload("res://assets/textures/triggers/Spawn.svg"))
	target_link.default_color = Color.CYAN
	update_target_link()

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not timer.is_stopped():
		if spawned_groups != null:
			var elapsed_time: float = timer.wait_time - timer.time_left
			for group in spawned_groups:
				if (elapsed_time > group.time or is_equal_approx(elapsed_time, group.time)) and group.loop_idx != _current_loop:
					if get_node(group.path).has_node("TriggerBase"):
						get_node(group.path).base.emit_signal("body_entered", _player)
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
	timer.start()
	if loop and not timer.timeout.is_connected(restart):
		timer.timeout.connect(restart)
	_current_loop += 1

func restart() -> void:
	await get_tree().create_timer(loop_delay).timeout
	if loop_count < 0 or _current_loop < loop_count:
		base.emit_signal("body_entered", _player)

func update_target_link() -> void:
	if len(spawned_groups) >= 1:
		target_link.target = get_node_or_null(spawned_groups[0].path)
	if len(spawned_groups) >= 2:
		for i in range(len(spawned_groups)-1):
			# Start loop at index 1, skipping the first spawned group since it already has a 'spawn' target link
			var group = get_node(spawned_groups[i].path)
			if not group.has_node("SpawnTargetLink"):
				var group_spawn_target_link: TargetLink = load("res://scenes/components/game_components/TargetLink.tscn").instantiate()
				group_spawn_target_link.default_color = Color.CYAN
				group_spawn_target_link.name = "SpawnTargetLink"
				group_spawn_target_link.z_index -= 1
				group_spawn_target_link.target = get_node_or_null(spawned_groups[i+1].path)
				group.add_child(group_spawn_target_link)
				group_spawn_target_link.owner = group.get_parent()
			else:
				group.get_node("SpawnTargetLink").target = get_node_or_null(spawned_groups[i+1].path)
