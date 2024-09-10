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

#region Constants
const GRAVITY: float = 5000.0 * 2
const SPEED := Vector2(625.0 * 2, 1100.0 * 2)
const SPEED_MINI := Vector2(625.0 * 2, 800.0 * 2)
const TERMINAL_VELOCITY := Vector2(0.0 * 2, 1500.0 * 2)
const FLY_TERMINAL_VELOCITY := Vector2(0.0 * 2, 900.0 * 2)
const FLY_GRAVITY_MULTIPLIER: float = 0.5
const UFO_GRAVITY_MULTIPLIER: float = 0.7
const WAVE_PLAYER_SCALE := Vector2(0.6, 0.6)
const MINI_PLAYER_SCALE := Vector2(0.6, 0.6)
const WAVE_TRAIL_WIDTH: float = 50.0
const WAVE_TRAIL_LENGTH: int = 250
const SPIDER_TRAIL: PackedScene = preload("res://scenes/components/game_components/SpiderTrail.tscn")
const DASH_BOOM: PackedScene = preload("res://scenes/components/game_components/GDDashBoom.tscn")
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
var dash_orb_rotation: float
var dash_orb_position: Vector2
var gameplay_rotation_degrees: float = 0.0
var gameplay_rotation: float:
	get():
		return deg_to_rad(gameplay_rotation_degrees)
var player_size: bool:
	set(value):
		player_size = value
		var _mini_scale: Vector2
		if value:
			_mini_scale = MINI_PLAYER_SCALE * WAVE_PLAYER_SCALE if displayed_gamemode == Gamemode.WAVE else MINI_PLAYER_SCALE
			create_tween().tween_property(self, "scale", _mini_scale, 0.25) \
					.set_ease(Tween.EASE_OUT) \
					.set_trans(Tween.TRANS_BACK)
		else:
			_mini_scale = Vector2.ONE * WAVE_PLAYER_SCALE if displayed_gamemode == Gamemode.WAVE else Vector2.ONE
			create_tween().tween_property(self, "scale", _mini_scale, 0.25) \
					.set_ease(Tween.EASE_OUT) \
					.set_trans(Tween.TRANS_BACK)
var can_hit_ceiling: bool
var jump_hold_disabled: bool
var speed_multiplier: float = 1.0
var gravity_multiplier: float = 1.0
var gameplay_trigger_gravity_multiplier: float = 1
var horizontal_direction: int = 1

# Queues
var orb_queue: Array[GDInteractible]
var pad_queue: Array[GDInteractible]

# Private
var _spider_jump_invulnerability_frames: int = 0
var _click_buffer_state: ClickBufferState
var _dash_orb_initial_gameplay_rotation: float
var _is_dashing: bool
var _dead: bool
var _is_flying_gamemode: bool
var _dual_instance: bool
var _last_spider_trail: SpiderTrail
var _last_spider_trail_height: float




@onready var _spider_animation_tree = $Icon/Spider/SpiderStateMachine as AnimationTree
@onready var _spider_state_machine: AnimationNodeStateMachinePlayback = _spider_animation_tree["parameters/playback"]

func _ready() -> void:
	_stop_dash()
	Engine.time_scale = 1.0
	displayed_gamemode = Gamemode.CUBE
	if not _dual_instance:
		LevelManager.player = self

func _physics_process(delta: float) -> void:
	if get_parent().has_level_started:
		up_direction = Vector2.UP.rotated(gameplay_rotation) * sign(gravity_multiplier)
		_rotate_sprite_degrees(delta)
		_update_wave_trail()
		if displayed_gamemode == Gamemode.SPIDER: _update_spider_state_machine()
		if displayed_gamemode == Gamemode.SWING: _update_swing_fire()
		velocity = _compute_velocity(delta, velocity, _get_direction(), _get_jump_state())
		move_and_slide()
		if _last_spider_trail != null:
			add_child(_last_spider_trail)
			_last_spider_trail.trail_global_position = $Icon/Spider/SpiderCast/SpiderTrailSpawnPoint.global_position if horizontal_direction > 0 \
				else $Icon/Spider/SpiderCast/SpiderTrailSpawnPointReverse.global_position
			_last_spider_trail.displayed_scale_y = abs(_last_spider_trail_height) * sign(gravity_multiplier)
			_last_spider_trail.displayed_scale_x = -horizontal_direction
			_last_spider_trail = null

func _get_direction() -> int:
	var _direction: int
	if LevelManager.platformer:
		_direction = int(Input.get_axis("move_left", "move_right"))
	else:
		_direction = horizontal_direction
	return _direction

func _get_jump_state() -> int:
	var jump_state: int
	if Input.is_action_just_pressed("jump") and is_on_floor() and jump_hold_disabled:
		jump_hold_disabled = false
	if _click_buffer_state == ClickBufferState.NOT_HOLDING and Input.is_action_just_pressed("jump") and not (is_on_floor() or is_on_ceiling()) \
		and internal_gamemode != Gamemode.SHIP and internal_gamemode != Gamemode.SWING and internal_gamemode != Gamemode.WAVE:
		_click_buffer_state = ClickBufferState.BUFFERING
	if _click_buffer_state == ClickBufferState.BUFFERING and not orb_queue.is_empty():
		_click_buffer_state = ClickBufferState.JUMPING
	if Input.is_action_just_released("jump") or (is_on_floor() or is_on_ceiling()):
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

func _compute_velocity(_delta: float,
		_previous_velocity: Vector2,
		_direction: int, _jump_state: int,
		) -> Vector2:
	var _velocity: Vector2 = _previous_velocity.rotated(-gameplay_rotation)
	var _speed: Vector2 = SPEED if not player_size else SPEED_MINI
	_is_flying_gamemode = (internal_gamemode == Gamemode.SHIP or internal_gamemode == Gamemode.SWING or internal_gamemode == Gamemode.WAVE)
	
	if _spider_jump_invulnerability_frames > 0: _spider_jump_invulnerability_frames -= 1

	if (internal_gamemode == Gamemode.SWING or internal_gamemode == Gamemode.BALL) and _jump_state == 1 and orb_queue.is_empty():
		gravity_multiplier *= -1

	#region Apply Gravity
	if not _is_dashing:
		if internal_gamemode == Gamemode.SHIP:
			_velocity.y += GRAVITY * _delta * gravity_multiplier * gameplay_trigger_gravity_multiplier * _jump_state * -1 * FLY_GRAVITY_MULTIPLIER
			_velocity.y = clamp(_velocity.y, -FLY_TERMINAL_VELOCITY.y, FLY_TERMINAL_VELOCITY.y)
		elif internal_gamemode == Gamemode.SWING:
			_velocity.y += GRAVITY * _delta * gravity_multiplier * gameplay_trigger_gravity_multiplier * FLY_GRAVITY_MULTIPLIER
			_velocity.y = clamp(_velocity.y, -FLY_TERMINAL_VELOCITY.y, FLY_TERMINAL_VELOCITY.y)
		elif internal_gamemode == Gamemode.WAVE:
			_velocity.y = SPEED.x * gravity_multiplier * gameplay_trigger_gravity_multiplier * _jump_state * -1
			if speed_multiplier > 0: _velocity.y *= speed_multiplier
			if player_size: _velocity.y *= 2
		elif not is_on_floor():
			if internal_gamemode == Gamemode.UFO:
				_velocity.y += GRAVITY * _delta * gravity_multiplier * gameplay_trigger_gravity_multiplier * UFO_GRAVITY_MULTIPLIER
			else:
				_velocity.y += GRAVITY * _delta * gravity_multiplier * gameplay_trigger_gravity_multiplier
			_velocity.y = clamp(_velocity.y, -TERMINAL_VELOCITY.y, TERMINAL_VELOCITY.y)
	#endregion

	if is_on_floor() and _jump_state == -1 and pad_queue.is_empty():
		_velocity.y = 0.0

	#region Apply pads velocity
	if not pad_queue.is_empty():
		var _colliding_pad: GDInteractible = pad_queue.pop_front()
		_colliding_pad._set_reverse(_colliding_pad._reverse)
		if internal_gamemode != Gamemode.WAVE:
			if _colliding_pad._pad_type == GDInteractible.Pad.YELLOW:
				_velocity.y = -_speed.y * (277.0/194.0)
			elif _colliding_pad._pad_type == GDInteractible.Pad.PINK:
				_velocity.y = -_speed.y * (179.0/194.0)
			elif _colliding_pad._pad_type == GDInteractible.Pad.RED:
				_velocity.y = -_speed.y * (365.0/194.0)
			elif _colliding_pad._pad_type == GDInteractible.Pad.REBOUND:
				_velocity.y = -rebound_velocity
			elif _colliding_pad._pad_type == GDInteractible.Pad.BLACK:
				_velocity.y = -_speed.y * -(260.0/194.0)
		# These pads are supposed to work with the wave
		if _colliding_pad._pad_type == GDInteractible.Pad.SPIDER:
			gravity_multiplier = Vector2.UP.rotated($Icon/Spider/SpiderCast.rotation).y
			_velocity.y = _get_spider_velocity_delta() * 1/_delta
			# _spider_jump_invulnerability_frames = 1
			_last_spider_trail_height = abs(_get_spider_velocity_delta()/_last_spider_trail.SPIDER_TRAIL_HEIGHT)
		elif _colliding_pad._pad_type == GDInteractible.Pad.BLUE:
			gravity_multiplier *= -1
			_velocity.y = _speed.y * (137.0/194.0) * gravity_multiplier * gameplay_trigger_gravity_multiplier if not displayed_gamemode == Gamemode.WAVE else 0.0
	#endregion

	#region Handle jump.
	if _jump_state == 1 and pad_queue.is_empty() and orb_queue.is_empty():
		if _is_flying_gamemode:
			pass
		elif internal_gamemode == Gamemode.SPIDER:
			gravity_multiplier *= -1
			_velocity.y = _get_spider_velocity_delta() * 1/_delta
			# _spider_jump_invulnerability_frames = 2
			_last_spider_trail_height = abs(_get_spider_velocity_delta()/_last_spider_trail.SPIDER_TRAIL_HEIGHT)
		elif internal_gamemode == Gamemode.BALL:
			_velocity.y = _speed.y * gravity_multiplier * 0.5
		elif internal_gamemode == Gamemode.ROBOT:
			_velocity.y = SPEED.x * gravity_multiplier * -1
		elif internal_gamemode == Gamemode.UFO:
			_velocity.y = -_speed.y * gravity_multiplier * UFO_GRAVITY_MULTIPLIER
		else:
			_velocity.y = -_speed.y * gravity_multiplier
	#endregion

	#region Dashing
	if _is_dashing:
		$DashFlame.visible = true
		$DashParticles.emitting = true
		$DashFlame.scale.x = abs($DashFlame.scale.x) * _direction
		if (is_on_floor() and sin(dash_orb_rotation) > 0) or (is_on_ceiling() and sin(dash_orb_rotation) < 0):
			_velocity.y = 0
		else:
			_velocity.y = tan(dash_orb_rotation - _dash_orb_initial_gameplay_rotation) * _speed.x
		if Input.is_action_just_released("jump"):
			_stop_dash()
	#endregion

	if _direction:
		_velocity.x = _direction * _speed.x * speed_multiplier * int(get_parent().has_level_started)
	elif LevelManager.platformer and internal_gamemode != Gamemode.WAVE:
		_velocity.x = lerp(_velocity.x, _speed.x * speed_multiplier * _direction, 0.5)
	else:
		_velocity.x = 0

	#region Apply orbs velocity
	if not orb_queue.is_empty() and (
		_click_buffer_state == ClickBufferState.JUMPING
		or (_jump_state == 1 and not _is_flying_gamemode)
		or (Input.is_action_just_pressed("jump") and _is_flying_gamemode)
		):
		var _colliding_orb: GDInteractible = orb_queue.pop_front()
		_colliding_orb._pulse_shrink()
		_colliding_orb._set_reverse(_colliding_orb._reverse)
		_click_buffer_state = ClickBufferState.BUFFER_USED
		if displayed_gamemode != Gamemode.WAVE:
			if _colliding_orb._orb_type == GDInteractible.Orb.YELLOW:
				_velocity.y = -_speed.y * (191.0/194.0)
			if _colliding_orb._orb_type == GDInteractible.Orb.PINK:
				_velocity.y = -_speed.y * (137.0/194.0)
			if _colliding_orb._orb_type == GDInteractible.Orb.RED:
				_velocity.y = -_speed.y * (268.0/194.0)
			if _colliding_orb._orb_type == GDInteractible.Orb.BLACK:
				_velocity.y = -_speed.y * -(260.0/194.0)
			if _colliding_orb._orb_type == GDInteractible.Orb.REBOUND:
				_velocity.y = -rebound_velocity
			if displayed_gamemode == Gamemode.SPIDER:
				_spider_state_machine.travel("jump")
		# These orbs are supposed to work with the wave
		if _colliding_orb._orb_type == GDInteractible.Orb.SPIDER:
			_colliding_orb._set_spider_props()
			gravity_multiplier *= -sign($Icon/Spider/SpiderCast.scale.y)
			_velocity.y = _get_spider_velocity_delta() * 1/_delta
			_spider_jump_invulnerability_frames = 2
			_last_spider_trail_height = abs(_get_spider_velocity_delta()/_last_spider_trail.SPIDER_TRAIL_HEIGHT)
			jump_hold_disabled = true
		if _colliding_orb._orb_type == GDInteractible.Orb.BLUE:
			gravity_multiplier *= -1
			_velocity.y = _speed.y * (137.0/194.0) * gravity_multiplier * gameplay_trigger_gravity_multiplier if not displayed_gamemode == Gamemode.WAVE else 0.0
		if _colliding_orb._orb_type == GDInteractible.Orb.GREEN:
			if displayed_gamemode == Gamemode.SPIDER:
				_spider_state_machine.travel("jump")
			gravity_multiplier *= -1
			_velocity.y = -_speed.y * (191.0/194.0) * gravity_multiplier * gameplay_trigger_gravity_multiplier if not displayed_gamemode == Gamemode.WAVE else 0.0
		if _colliding_orb._orb_type == GDInteractible.Orb.DASH_GREEN:
			_colliding_orb._set_dash_props()
			var _last_dash_boom = DASH_BOOM.instantiate()
			_last_dash_boom.position = to_local(dash_orb_position)
			add_child(_last_dash_boom)
			_dash_orb_initial_gameplay_rotation = gameplay_rotation
			$DashFlame.rotation = dash_orb_rotation * _direction
			_is_dashing = true
		if _colliding_orb._orb_type == GDInteractible.Orb.DASH_MAGENTA:
			_colliding_orb._set_dash_props()
			var _last_dash_boom = DASH_BOOM.instantiate()
			_last_dash_boom.position = to_local(dash_orb_position)
			add_child(_last_dash_boom)
			_dash_orb_initial_gameplay_rotation = gameplay_rotation
			$DashFlame.rotation = dash_orb_rotation * _direction
			gravity_multiplier *= -1
			_is_dashing = true
		if _colliding_orb._orb_type == GDInteractible.Orb.TELEPORT:
			var _velocity_override: Vector2 = _colliding_orb._teleport_player()
			if _colliding_orb._override_player_velocity: _velocity = _velocity_override * 1/_delta
		if _colliding_orb._orb_type == GDInteractible.Orb.TOGGLE:
			var toggle = ObjectToggle.new()
			add_child(toggle)
			toggle._toggle(_colliding_orb.toggled_groups)
			toggle.queue_free()
			jump_hold_disabled = true
	
		if _colliding_orb.multi_usage:
			orb_queue.append(_colliding_orb)
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
	if not _is_dashing:
		if not is_on_floor() and not is_on_ceiling() and speed_multiplier > 0.0:
			$Icon/Cube.rotation_degrees += delta * gravity_multiplier * 400 * _get_direction()
		else:
			$Icon/Cube.rotation_degrees = lerpf($Icon/Cube.rotation_degrees, snapped($Icon/Cube.rotation_degrees, 90), 0.5)
	else:
		$Icon/Cube.rotation_degrees += delta * 800 * _get_direction()
	#endregion
	#region ship/swing
	$Icon/Ship.scale.y = sign(gravity_multiplier)
	$Icon/Swing.scale.y = 1.0
	if _get_direction() != 0:
		$Icon/Ship.scale.x = sign(_get_direction())
		$Icon/Swing.scale.x = sign(_get_direction())
	if not _is_dashing:
		if not is_on_floor() and not is_on_ceiling() and speed_multiplier > 0.0:
			$Icon/Ship.rotation_degrees = lerpf($Icon/Ship.rotation, velocity.rotated(-gameplay_rotation).y * delta * _get_direction() * 3, 0.5)
			$Icon/Swing.rotation_degrees = lerpf($Icon/Swing.rotation, velocity.rotated(-gameplay_rotation).y * delta * _get_direction() * 3, 0.5)
		else:
			$Icon/Ship.rotation_degrees = lerpf($Icon/Ship.rotation_degrees, 0.0, 0.5)
			$Icon/Swing.rotation_degrees = lerpf($Icon/Swing.rotation_degrees, 0.0, 0.5)
	else:
		$Icon/Ship.rotation = lerpf($Icon/Ship.rotation, dash_orb_rotation * _get_direction(), 0.5)
		$Icon/Swing.rotation = lerpf($Icon/Swing.rotation, dash_orb_rotation * _get_direction(), 0.5)
	#endregion
	#region wave
	$Icon/Wave.scale.y = 1.0
	if _get_direction() != 0:
		$Icon/Wave.scale.x = sign(_get_direction())
	if not _is_dashing:
		if not is_on_floor() and not is_on_ceiling():
			if velocity.rotated(-gameplay_rotation).x != 0.0:
				if not player_size:
					$Icon/Wave/Icon.rotation_degrees = lerpf($Icon/Wave/Icon.rotation_degrees, 45.0 * -_get_jump_state() * sign(gravity_multiplier), 0.25)
				else:
					$Icon/Wave/Icon.rotation_degrees = lerpf($Icon/Wave/Icon.rotation_degrees, 60.0 * -_get_jump_state() * sign(gravity_multiplier), 0.25)
			else:
				$Icon/Wave/Icon.rotation_degrees = lerpf($Icon/Wave/Icon.rotation_degrees, 90.0 * -_get_jump_state() * sign(gravity_multiplier), 0.25)
		else:
			$Icon/Wave/Icon.rotation_degrees = lerpf($Icon/Wave/Icon.rotation_degrees * _get_direction(), 0.0, 0.5)
	else:
		$Icon/Wave/Icon.rotation = lerpf($Icon/Wave/Icon.rotation, dash_orb_rotation * _get_direction(), 0.5)
	#endregion
	#region ufo
	$Icon/UFO.scale.y = sign(gravity_multiplier)
	if _get_direction() != 0:
		$Icon/UFO.scale.x = sign(_get_direction())
	if not _is_dashing:
		if not is_on_floor() and not is_on_ceiling() and speed_multiplier > 0.0:
			$Icon/UFO.rotation_degrees = lerpf($Icon/UFO.rotation_degrees, velocity.rotated(-gameplay_rotation).y * delta * _get_direction() * 0.2, 0.5)
		else:
			$Icon/UFO.rotation_degrees = lerpf($Icon/UFO.rotation_degrees, 0.0, 0.5)
	else:
		$Icon/UFO.rotation = lerpf($Icon/UFO.rotation, dash_orb_rotation * _get_direction(), 0.5)
	#endregion
	#region ball
	$Icon/Ball.scale.y = 1.0
	if speed_multiplier > 0.0:
		$Icon/Ball.rotation_degrees += delta * gravity_multiplier * 0.5 * gameplay_trigger_gravity_multiplier * velocity.rotated(-gameplay_rotation).x
	#endregion
	#region spider/robot
	if _get_direction() != 0:
		$Icon/Spider.scale.x = sign(_get_direction())
		$Icon/Robot.scale.x = sign(_get_direction())
	$Icon/Spider.scale.y = sign(gravity_multiplier)
	$Icon/Robot.scale.y = sign(gravity_multiplier)
	#endregion

func _update_swing_fire() -> void:
	if gravity_multiplier < 0.0:
		$Icon/Swing/FireBoostTop.position = $Icon/Swing/FireBoostTop.position.lerp(Vector2.ZERO, 0.2)
		$Icon/Swing/FireBoostBottom.position = $Icon/Swing/FireBoostBottom.position.lerp(Vector2(-54.0, 63.0), 0.2)
	else:
		$Icon/Swing/FireBoostTop.position = $Icon/Swing/FireBoostTop.position.lerp(Vector2(-54.0, -63.0), 0.2)
		$Icon/Swing/FireBoostBottom.position = $Icon/Swing/FireBoostBottom.position.lerp(Vector2.ZERO, 0.2)

func _update_wave_trail() -> void:
	if not player_size:
		$WaveTrail.width = lerpf($WaveTrail.width, WAVE_TRAIL_WIDTH, 0.25)
		$WaveTrail2.width = lerpf($WaveTrail2.width, WAVE_TRAIL_WIDTH * 0.5, 0.25)
	else:
		$WaveTrail.width = lerpf($WaveTrail.width, WAVE_TRAIL_WIDTH * MINI_PLAYER_SCALE.y, 0.25)
		$WaveTrail2.width = lerpf($WaveTrail2.width, WAVE_TRAIL_WIDTH * MINI_PLAYER_SCALE.y * 0.5, 0.25)
	if displayed_gamemode == Gamemode.WAVE:
		$WaveTrail.modulate.a = 1.0
		$WaveTrail2.modulate.a = 1.0
		$WaveTrail.length = lerpf($WaveTrail.length, WAVE_TRAIL_LENGTH, 0.2)
		$WaveTrail2.length = lerpf($WaveTrail.length, WAVE_TRAIL_LENGTH, 0.2)
	else:
		$WaveTrail.length = 0
		$WaveTrail2.length = 0
		$WaveTrail.modulate.a = lerpf($WaveTrail.modulate.a, 0.0, 0.1)
		$WaveTrail2.modulate.a = lerpf($WaveTrail.modulate.a, 0.0, 0.1)
		# for i in range(2):
		# 	if $WaveTrail.get_point_count() > $WaveTrail.length:
		# 		$WaveTrail.remove_point($WaveTrail.get_point_count() - 2)
		# 		$WaveTrail2.remove_point($WaveTrail2.get_point_count() - 2)

func _clear_wave_trail() -> void:
	$WaveTrail.clear_points()
	$WaveTrail2.clear_points()

func _get_spider_velocity_delta() -> float:
	var _target_position = $Icon/Spider/SpiderCast.get_collision_point(0)
	var _spider_velocity_delta: float = abs((_target_position - position).rotated(-gameplay_rotation).y)
	_spider_velocity_delta -= $GroundCollider.shape.size.y/2 * scale.y
	_last_spider_trail = SPIDER_TRAIL.instantiate()
	_last_spider_trail.trail_rotation = gameplay_rotation
	return _spider_velocity_delta * gravity_multiplier * gameplay_trigger_gravity_multiplier

func _update_spider_state_machine() -> void:
	# `jump` was moved to _compute_velocity to only be triggered with orbs and pads
	# _spider_state_machine.travel("jump")
	if _is_dashing or (_get_jump_state() == -1 and not is_on_floor() and not is_on_ceiling() and not is_on_wall()):
		_spider_state_machine.travel("fall")
	elif speed_multiplier >= GDInteractible.SPEEDS[GDInteractible.SpeedPortal.SPEED_4X]:
		_spider_animation_tree["parameters/run/PlayerSpeed/scale"] = speed_multiplier/GDInteractible.SPEEDS[GDInteractible.SpeedPortal.SPEED_4X]
		_spider_state_machine.travel("run")
	elif speed_multiplier == GDInteractible.SPEEDS[GDInteractible.SpeedPortal.SPEED_0X] or _get_direction() == 0:
		_spider_state_machine.travel("idle")
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

func _stop_dash() -> void:
	_is_dashing = false
	dash_orb_rotation = 0.0
	$DashFlame.hide()
	$DashParticles.emitting = false
