extends CharacterBody2D

class_name Player

enum Gamemode {
	CUBE,
	SHIP,
	UFO,
	BALL,
	WAVE,
	ROBOT,
	SPIDER,
	SWING,
}

enum ClickBufferState {
	NOT_HOLDING,
	BUFFERING,
	JUMPING,
	BUFFER_USED,
}

enum PlayerScale {
	MINI,
	NORMAL,
	BIG,
}

#region Constants
const GRAVITY: float = 5000.0 * 2
const SPEED := Vector2(625.0 * 2, 1100.0 * 2)
const SPEED_MINI := Vector2(625.0 * 2, 800.0 * 2)
const SPEED_BIG := Vector2(625.0 * 2, 1500.0 * 2)
const TERMINAL_VELOCITY := Vector2(0.0 * 2, 1500.0 * 2)
const FLY_TERMINAL_VELOCITY := Vector2(0.0 * 2, 900.0 * 2)
const FLY_GRAVITY_MULTIPLIER: float = 0.5
const UFO_GRAVITY_MULTIPLIER: float = 0.7
const PLAYER_SCALE_WAVE := Vector2(0.6, 0.6)
const PLAYER_SCALE_MINI := Vector2(0.6, 0.6)
const PLAYER_SCALE_NORMAL := Vector2.ONE
const PLAYER_SCALE_BIG := Vector2(1.4, 1.4)
const WAVE_TRAIL_WIDTH: float = 50.0
const WAVE_TRAIL_LENGTH: int = 250
const SPIDER_TRAIL: PackedScene = preload("res://scenes/components/game_components/SpiderTrail.tscn")
const DASH_BOOM: PackedScene = preload("res://scenes/components/game_components/DashBoom.tscn")
const ICON_LERP_FACTOR := 0.5
const PLATFORMER_ACCELERATION := 5
#endregion

@export var displayed_gamemode: Gamemode:
	set(value):
		displayed_gamemode = value
		for icon in $Icon.get_children():
			if icon.gamemode != value: icon.hide()
			else: icon.show()
@export var internal_gamemode: Gamemode

# Public
var rebound_velocity: float
var gameplay_rotation_degrees: float = 0.0
var gameplay_rotation: float:
	get():
		return deg_to_rad(gameplay_rotation_degrees)
var player_scale: PlayerScale = PlayerScale.NORMAL:
	set(value):
		player_scale = value
		var player_scale_value: Vector2
		match value:
			PlayerScale.MINI:
				player_scale_value = PLAYER_SCALE_MINI
			PlayerScale.NORMAL:
				player_scale_value = PLAYER_SCALE_NORMAL
			PlayerScale.BIG:
				player_scale_value = PLAYER_SCALE_BIG
		if displayed_gamemode == Gamemode.WAVE:
			player_scale_value *= PLAYER_SCALE_WAVE
		create_tween().tween_property(self, "scale", player_scale_value, 0.25) \
				.set_ease(Tween.EASE_OUT) \
				.set_trans(Tween.TRANS_BACK)
var can_hit_ceiling: bool
var jump_hold_disabled: bool
var speed_multiplier: float = 1.0
var gravity_multiplier: float = 1.0
var gameplay_trigger_gravity_multiplier: float = 1
var horizontal_direction: int = 1
var speed: Vector2:
	get():
		match player_scale:
			PlayerScale.MINI:
				return SPEED_MINI
			PlayerScale.NORMAL:
				return SPEED
			PlayerScale.BIG:
				return SPEED_BIG
			_:
				return SPEED
var dash_control: FireDashComponent = null
var speed_0_portal_control: SpeedChangerComponent = null

# Queues
var orb_queue: Array[OrbInteractable]
var pad_queue: Array[PadInteractable]

# Private
var _spider_jump_invulnerability_frames: int = 0
var _click_buffer_state: ClickBufferState
var _dead: bool
var _is_flying_gamemode: bool
var _dual_instance: bool
var _last_spider_trail: SpiderTrail
var _last_spider_trail_height: float




@onready var _spider_animation_tree = $Icon/Spider/SpiderStateMachine as AnimationTree
@onready var _spider_state_machine: AnimationNodeStateMachinePlayback = _spider_animation_tree["parameters/playback"]

func _ready() -> void:
	platform_on_leave = PlatformOnLeave.PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY if not LevelManager.platformer else PlatformOnLeave.PLATFORM_ON_LEAVE_ADD_VELOCITY
	dash_control = null
	Engine.time_scale = 1.0
	displayed_gamemode = Gamemode.CUBE
	if not _dual_instance:
		LevelManager.player = self

func _physics_process(delta: float) -> void:
	if get_parent().has_level_started:
		up_direction = Vector2.UP.rotated(gameplay_rotation) * sign(gravity_multiplier)
		_rotate_sprite_degrees(delta)
		_update_wave_trail(delta)
		if displayed_gamemode == Gamemode.SPIDER: _update_spider_state_machine()
		if displayed_gamemode == Gamemode.SWING: _update_swing_fire(delta)
		velocity = _compute_velocity(delta, velocity, get_direction(), _get_jump_state())
		move_and_slide()
		if _last_spider_trail != null:
			add_child(_last_spider_trail)
			_last_spider_trail.trail_global_position = $Icon/Spider/SpiderCast/SpiderTrailSpawnPoint.global_position if horizontal_direction > 0 \
				else $Icon/Spider/SpiderCast/SpiderTrailSpawnPointReverse.global_position
			_last_spider_trail.displayed_scale_y = abs(_last_spider_trail_height) * sign(gravity_multiplier)
			_last_spider_trail.displayed_scale_x = -horizontal_direction
			_last_spider_trail = null
		#region 0x speed portal position nudge
		if speed_0_portal_control:
			var global_position_normalized = global_position.rotated(-gameplay_rotation)
			var portal_global_position_normalized = speed_0_portal_control.parent.global_position.rotated(-gameplay_rotation)
			global_position = Vector2(global_position_normalized.lerp(portal_global_position_normalized, 1-exp(-delta * 60 * 0.3)).rotated(gameplay_rotation).x, global_position.y)
			if is_equal_approx(global_position_normalized.x, portal_global_position_normalized.x):
				speed_0_portal_control = null
		#endregion

func get_direction() -> int:
	var direction: int
	if LevelManager.platformer:
		direction = int(Input.get_axis("move_left", "move_right"))
		if direction != 0:
			horizontal_direction = direction
	else:
		direction = horizontal_direction
	return direction

func _get_jump_state() -> int:
	var jump_state: int
	if Input.is_action_just_pressed("jump") and is_on_floor() and jump_hold_disabled:
		jump_hold_disabled = false
	if _click_buffer_state == ClickBufferState.NOT_HOLDING and Input.is_action_just_pressed("jump") and not (is_on_floor() or is_on_ceiling()) \
		and internal_gamemode != Gamemode.SHIP and internal_gamemode != Gamemode.SWING and internal_gamemode != Gamemode.WAVE:
		_click_buffer_state = ClickBufferState.BUFFERING
	if _click_buffer_state == ClickBufferState.BUFFERING and not orb_queue.is_empty():
		_click_buffer_state = ClickBufferState.JUMPING
	if Input.is_action_just_released("jump") or ((is_on_floor() or is_on_ceiling()) and not Input.is_action_pressed("jump")):
		_click_buffer_state = ClickBufferState.NOT_HOLDING
	if jump_hold_disabled:
		jump_state = -1
	elif internal_gamemode == Gamemode.CUBE:
		jump_state = 1 if (Input.is_action_pressed("jump") and (is_on_floor() or is_on_ceiling())) else -1
	elif internal_gamemode == Gamemode.ROBOT:
		if Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_ceiling()):
			$RobotTimer.start(0.25)
		if Input.is_action_just_released("jump"):
			$RobotTimer.stop()
		jump_state = 1 if Input.is_action_pressed("jump") and $RobotTimer.get_time_left() > 0 else -1
	elif internal_gamemode == Gamemode.SHIP or (internal_gamemode == Gamemode.WAVE and not LevelManager.platformer):
		jump_state = 1 if Input.is_action_pressed("jump") else -1
	elif internal_gamemode == Gamemode.WAVE and LevelManager.platformer:
		jump_state = 0
		if Input.is_action_pressed("jump"): jump_state = 1
		if Input.is_action_pressed("platformer_wave_down"): jump_state = -1
	elif internal_gamemode == Gamemode.UFO or internal_gamemode == Gamemode.SWING:
		jump_state = 1 if Input.is_action_just_pressed("jump") else -1
	elif internal_gamemode == Gamemode.BALL or internal_gamemode == Gamemode.SPIDER:
		jump_state = 1 if (Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_ceiling())) else -1
	return jump_state

func _compute_velocity(delta: float,
		previous_velocity: Vector2,
		direction: int, jump_state: int,
		) -> Vector2:
	var _velocity: Vector2 = previous_velocity.rotated(-gameplay_rotation)
	_is_flying_gamemode = (internal_gamemode == Gamemode.SHIP or internal_gamemode == Gamemode.SWING or internal_gamemode == Gamemode.WAVE)
	
	if _spider_jump_invulnerability_frames > 0: _spider_jump_invulnerability_frames -= 1

	if (internal_gamemode == Gamemode.SWING or internal_gamemode == Gamemode.BALL) and jump_state == 1 and orb_queue.is_empty():
		gravity_multiplier *= -1

	#region Apply Gravity
	if not dash_control:
		if internal_gamemode == Gamemode.SHIP:
			_velocity.y += GRAVITY * delta * gravity_multiplier * gameplay_trigger_gravity_multiplier * jump_state * -1 * FLY_GRAVITY_MULTIPLIER
			_velocity.y = clamp(_velocity.y, -FLY_TERMINAL_VELOCITY.y, FLY_TERMINAL_VELOCITY.y)
		elif internal_gamemode == Gamemode.SWING:
			_velocity.y += GRAVITY * delta * gravity_multiplier * gameplay_trigger_gravity_multiplier * FLY_GRAVITY_MULTIPLIER
			_velocity.y = clamp(_velocity.y, -FLY_TERMINAL_VELOCITY.y, FLY_TERMINAL_VELOCITY.y)
		elif internal_gamemode == Gamemode.WAVE:
			_velocity.y = SPEED.x * gravity_multiplier * gameplay_trigger_gravity_multiplier * jump_state * -1
			if speed_multiplier > 0: _velocity.y *= speed_multiplier
			if player_scale == PlayerScale.MINI:
				_velocity.y *= 2
			elif player_scale == PlayerScale.BIG:
				_velocity.y *= 0.5
		elif not is_on_floor() and not $GroundRaycast.is_colliding():
			if internal_gamemode == Gamemode.UFO:
				_velocity.y += GRAVITY * delta * gravity_multiplier * gameplay_trigger_gravity_multiplier * UFO_GRAVITY_MULTIPLIER
			else:
				_velocity.y += GRAVITY * delta * gravity_multiplier * gameplay_trigger_gravity_multiplier
			_velocity.y = clamp(_velocity.y, -TERMINAL_VELOCITY.y, TERMINAL_VELOCITY.y)
	#endregion

	if is_on_floor() and jump_state == -1 and pad_queue.is_empty():
		_velocity.y = 0.0

	#region Apply pads velocity
	if not pad_queue.is_empty():
		var colliding_pad: PadInteractable = pad_queue.pop_front()
		if not colliding_pad.single_usage:
			pad_queue.append(colliding_pad)
		for component in colliding_pad.components:
			if internal_gamemode != Gamemode.WAVE and (component is JumpBoostComponent or component is ReboundComponent):
				_velocity.y = component.get_velocity(self)
				if displayed_gamemode == Gamemode.SPIDER:
					_spider_state_machine.travel("jump")
	#endregion

	#region Handle jump.
	if jump_state == 1 and pad_queue.is_empty() and orb_queue.is_empty():
		if _is_flying_gamemode:
			pass
		elif internal_gamemode == Gamemode.SPIDER:
			gravity_multiplier *= -1
			_velocity.y = _get_spider_velocity_delta() * 1/delta
		elif internal_gamemode == Gamemode.BALL:
			_velocity.y = speed.y * gravity_multiplier * 0.5
		elif internal_gamemode == Gamemode.ROBOT:
			_velocity.y = SPEED.x * gravity_multiplier * -1
		elif internal_gamemode == Gamemode.UFO:
			_velocity.y = -speed.y * gravity_multiplier * UFO_GRAVITY_MULTIPLIER
		else:
			_velocity.y = -speed.y * gravity_multiplier
	#endregion

	if not LevelManager.platformer or (LevelManager.platformer and internal_gamemode == Gamemode.WAVE):
		if direction:
			_velocity.x = direction * speed.x * speed_multiplier * int(get_parent().has_level_started)
		else:
			_velocity.x = 0
	else:
		if direction:
			_velocity.x = move_toward(
					_velocity.x,
					direction * speed.x * speed_multiplier * int(get_parent().has_level_started),
					speed.x * PLATFORMER_ACCELERATION * delta * speed_multiplier * int(get_parent().has_level_started),
			)
		else:
			_velocity.x = move_toward(
					_velocity.x,
					0.0,
					speed.x * delta * speed_multiplier * PLATFORMER_ACCELERATION * int(get_parent().has_level_started),
			)

	#region Apply orbs velocity
	if not orb_queue.is_empty() and (
			_click_buffer_state == ClickBufferState.JUMPING
			or (jump_state == 1 and not _is_flying_gamemode and not _click_buffer_state == ClickBufferState.BUFFER_USED)
			or (Input.is_action_just_pressed("jump") and _is_flying_gamemode)):
		var colliding_orb: OrbInteractable = orb_queue.pop_front()
		_click_buffer_state = ClickBufferState.BUFFER_USED
		if not colliding_orb.single_usage:
			orb_queue.append(colliding_orb)
		colliding_orb.pressed.emit(self)
		for component in colliding_orb.components:
			if internal_gamemode != Gamemode.WAVE and (component is JumpBoostComponent or component is ReboundComponent):
				_velocity.y = component.get_velocity(self)
				if displayed_gamemode == Gamemode.SPIDER:
					_spider_state_machine.travel("jump")
			elif component is SpiderDashComponent:
				component.set_dash_flip_state(self)
				gravity_multiplier = -sign($Icon/Spider/SpiderCast.scale.y)
				_velocity.y = _get_spider_velocity_delta() * 1/delta
				jump_hold_disabled = true
	#endregion

	#region Dash orb velocity
	if dash_control:
		_velocity = dash_control.path.get_velocity(self)
		if Input.is_action_just_released("jump"):
			dash_control.stop(self)
	#endregion

	if not _dead:
		return _velocity.rotated(gameplay_rotation)
	else:
		return Vector2.ZERO

func _rotate_sprite_degrees(delta: float):
	$Icon.rotation = gameplay_rotation
	#region cube
	$Icon/Cube.scale.y = 1.0
	if horizontal_direction != 0:
		$Icon/Cube.scale.x = horizontal_direction
	if not dash_control:
		if not is_on_floor() and not is_on_ceiling() and speed_multiplier > 0.0:
			$Icon/Cube.rotation_degrees += delta * gravity_multiplier * 400 * get_direction()
		else:
			$Icon/Cube.rotation_degrees = lerpf($Icon/Cube.rotation_degrees, snapped($Icon/Cube.rotation_degrees, 90), ICON_LERP_FACTOR)
	else:
		$Icon/Cube.rotation_degrees += delta * 800 * dash_control.initial_horizontal_direction
	#endregion
	#region ship/swing
	$Icon/Ship.scale.y = sign(gravity_multiplier)
	$Icon/Swing.scale.y = 1.0
	if get_direction() != 0:
		$Icon/Ship.scale.x = sign(get_direction())
		$Icon/Swing.scale.x = sign(get_direction())
	if not dash_control:
		if not is_on_floor() and not is_on_ceiling() and speed_multiplier > 0.0:
			$Icon/Ship.rotation_degrees = lerpf($Icon/Ship.rotation, velocity.rotated(-gameplay_rotation).y * delta * get_direction() * 3, ICON_LERP_FACTOR)
			$Icon/Swing.rotation_degrees = lerpf($Icon/Swing.rotation, velocity.rotated(-gameplay_rotation).y * delta * get_direction() * 3, ICON_LERP_FACTOR)
		else:
			$Icon/Ship.rotation_degrees = lerpf($Icon/Ship.rotation_degrees, 0.0, ICON_LERP_FACTOR)
			$Icon/Swing.rotation_degrees = lerpf($Icon/Swing.rotation_degrees, 0.0, ICON_LERP_FACTOR)
	else:
		$Icon/Ship.rotation = lerpf($Icon/Ship.rotation, dash_control.angle * get_direction(), ICON_LERP_FACTOR)
		$Icon/Swing.rotation = lerpf($Icon/Swing.rotation, dash_control.angle * get_direction(), ICON_LERP_FACTOR)
	#endregion
	#region wave
	$Icon/Wave.scale.y = 1.0
	if get_direction() != 0:
		$Icon/Wave.scale.x = sign(get_direction())
	if not dash_control:
		if not is_on_floor() and not is_on_ceiling():
			if velocity.rotated(-gameplay_rotation).x != 0.0:
				if player_scale == PlayerScale.NORMAL:
					$Icon/Wave/Icon.rotation_degrees = lerpf($Icon/Wave/Icon.rotation_degrees, 45.0 * -_get_jump_state() * sign(gravity_multiplier), 0.25)
				elif player_scale == PlayerScale.MINI:
					$Icon/Wave/Icon.rotation_degrees = lerpf($Icon/Wave/Icon.rotation_degrees, 60.0 * -_get_jump_state() * sign(gravity_multiplier), 0.25)
				elif player_scale == PlayerScale.BIG:
					$Icon/Wave/Icon.rotation_degrees = lerpf($Icon/Wave/Icon.rotation_degrees, 30.0 * -_get_jump_state() * sign(gravity_multiplier), 0.25)
			else:
				$Icon/Wave/Icon.rotation_degrees = lerpf($Icon/Wave/Icon.rotation_degrees, 90.0 * -_get_jump_state() * sign(gravity_multiplier), 0.25)
		else:
			$Icon/Wave/Icon.rotation_degrees = lerpf($Icon/Wave/Icon.rotation_degrees * get_direction(), 0.0, ICON_LERP_FACTOR)
	else:
		$Icon/Wave/Icon.rotation = lerpf($Icon/Wave/Icon.rotation, dash_control.angle * get_direction(), ICON_LERP_FACTOR)
	#endregion
	#region ufo
	$Icon/UFO.scale.y = sign(gravity_multiplier)
	if get_direction() != 0:
		$Icon/UFO.scale.x = sign(get_direction())
	if not dash_control:
		if not is_on_floor() and not is_on_ceiling() and speed_multiplier > 0.0:
			$Icon/UFO.rotation_degrees = lerpf($Icon/UFO.rotation_degrees, velocity.rotated(-gameplay_rotation).y * delta * get_direction() * 0.2, ICON_LERP_FACTOR)
		else:
			$Icon/UFO.rotation_degrees = lerpf($Icon/UFO.rotation_degrees, 0.0, ICON_LERP_FACTOR)
	else:
		$Icon/UFO.rotation = lerpf($Icon/UFO.rotation, dash_control.angle * get_direction(), ICON_LERP_FACTOR)
	#endregion
	#region ball
	$Icon/Ball.scale.y = 1.0
	if speed_multiplier > 0.0:
		var rotation_delta := delta * 0.6 * gameplay_trigger_gravity_multiplier * (velocity.rotated(-gameplay_rotation).x / speed_multiplier)
		if not dash_control:
			rotation_delta *= gravity_multiplier
		$Icon/Ball.rotation_degrees += rotation_delta
	#endregion
	#region spider/robot
	if get_direction() != 0:
		$Icon/Spider.scale.x = sign(get_direction())
		$Icon/Robot.scale.x = sign(get_direction())
	$Icon/Spider.scale.y = sign(gravity_multiplier)
	$Icon/Robot.scale.y = sign(gravity_multiplier)
	#endregion

func _update_swing_fire(delta: float) -> void:
	if gravity_multiplier < 0.0:
		$Icon/Swing/FireBoostTop.position = $Icon/Swing/FireBoostTop.position.lerp(Vector2.ZERO, 1-exp(-delta * 12))
		$Icon/Swing/FireBoostBottom.position = $Icon/Swing/FireBoostBottom.position.lerp(Vector2(-54.0, 63.0), 1-exp(-delta * 12))
	else:
		$Icon/Swing/FireBoostTop.position = $Icon/Swing/FireBoostTop.position.lerp(Vector2(-54.0, -63.0), 1-exp(-delta * 12))
		$Icon/Swing/FireBoostBottom.position = $Icon/Swing/FireBoostBottom.position.lerp(Vector2.ZERO, 1-exp(-delta * 12))

func _update_wave_trail(delta: float) -> void:
	var wave_trail_width := WAVE_TRAIL_WIDTH
	if player_scale == PlayerScale.MINI:
		wave_trail_width *= PLAYER_SCALE_MINI.y
	elif player_scale == PlayerScale.BIG:
		wave_trail_width *= PLAYER_SCALE_BIG.y
	$WaveTrail.width = lerpf($WaveTrail.width, wave_trail_width, 0.25)
	$WaveTrail2.width = lerpf($WaveTrail2.width, wave_trail_width * 0.5, 0.25)
	if displayed_gamemode == Gamemode.WAVE:
		$WaveTrail.modulate.a = 1.0
		$WaveTrail2.modulate.a = 1.0
		$WaveTrail.length = lerpf($WaveTrail.length, WAVE_TRAIL_LENGTH, 1-exp(-delta * 12))
		$WaveTrail2.length = lerpf($WaveTrail.length, WAVE_TRAIL_LENGTH, 1-exp(-delta * 12))
	else:
		$WaveTrail.length = 0
		$WaveTrail2.length = 0
		$WaveTrail.modulate.a = move_toward($WaveTrail.modulate.a, 0.0, delta * 12)
		$WaveTrail2.modulate.a = move_toward($WaveTrail2.modulate.a, 0.0, delta * 12)
		if is_zero_approx($WaveTrail.modulate.a):
			$WaveTrail.clear_points()
		if is_zero_approx($WaveTrail2.modulate.a):
			$WaveTrail2.clear_points()

func _get_spider_velocity_delta() -> float:
	var _target_position = $Icon/Spider/SpiderCast.get_collision_point(0)
	var _spider_velocity_delta: float = abs((_target_position - position).rotated(-gameplay_rotation).y)
	_spider_velocity_delta -= $GroundCollider.shape.size.y/2 * scale.y
	var result := _spider_velocity_delta * gravity_multiplier * gameplay_trigger_gravity_multiplier
	_last_spider_trail = SPIDER_TRAIL.instantiate()
	_last_spider_trail_height = abs(result/SpiderTrail.SPIDER_TRAIL_HEIGHT)
	_last_spider_trail.scale.x = horizontal_direction
	_last_spider_trail.trail_rotation = gameplay_rotation
	return result

func _update_spider_state_machine() -> void:
	# `jump` was moved to _compute_velocity to only be triggered with orbs and pads
	# _spider_state_machine.travel("jump")
	if dash_control or (_get_jump_state() == -1 and not is_on_floor() and not is_on_ceiling() and not is_on_wall()):
		_spider_state_machine.travel("fall")
	elif speed_multiplier == 0 or get_direction() == 0:
		_spider_state_machine.travel("idle")
	elif speed_multiplier >= 1.849:
		_spider_animation_tree["parameters/run/PlayerSpeed/scale"] = speed_multiplier/1.849
		_spider_state_machine.travel("run")
	else:
		_spider_animation_tree["parameters/walk/PlayerSpeed/scale"] = speed_multiplier
		_spider_state_machine.travel("walk")

func _player_death() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
	_dead = true
	$Icon.hide()
	$DeathEffect.frame = 0
	$DeathEffect.play()
	$DeathParticles.restart()
	SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/DeathSound.mp3")

func _on_death_restart() -> void:
	get_tree().reload_current_scene()

func _on_kill_collider_solid_body_entered(_body:Node2D) -> void:
	if _spider_jump_invulnerability_frames == 0:
		$DeathAnimator.play("DeathAnimation")

func _on_kill_collider_hazard_body_entered(_body:Node2D) -> void:
	if _spider_jump_invulnerability_frames == 0:
		$DeathAnimator.play("DeathAnimation")
