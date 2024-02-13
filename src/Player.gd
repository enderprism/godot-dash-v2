extends CharacterBody2D

class_name Player

signal teleported
signal orb_clicked

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

const GRAVITY: float = 5000.0 * 2
const SPEED: Vector2 = Vector2(625.0 * 2, 1100.0 * 2)
const SPEED_MINI: Vector2 = Vector2(625.0 * 2, 800.0 * 2)
const TERMINAL_VELOCITY: Vector2 = Vector2(0.0 * 2, 1500.0 * 2)
const FLY_TERMINAL_VELOCITY: Vector2 = Vector2(0.0 * 2, 900.0 * 2)
const FLY_GRAVITY_MULTIPLIER: float = 0.5
const UFO_GRAVITY_MULTIPLIER: float = 0.9
const WAVE_PLAYER_SCALE: Vector2 = Vector2(0.6, 0.6)
const MINI_PLAYER_SCALE: Vector2 = Vector2(0.6, 0.6)
const WAVE_TRAIL_WIDTH: float = 50.0
const SPIDER_TRAIL: PackedScene = preload("res://scenes/components/game_components/GDSpiderTrail.tscn")
const DASH_BOOM: PackedScene = preload("res://scenes/components/game_components/GDDashBoom.tscn")

@export var gamemode: Gamemode:
	set(value):
		gamemode = value
		for icon in $Icon.get_children():
			if icon.gamemode != value: icon.hide()
			else: icon.show()

var _click_buffer_state: ClickBufferState
var _reverse_direction_buffer: int
var _teleport_position_buffer: Vector2
var _teleport_override_velocity: bool = false
var _teleport_velocity_buffer: Vector2
var _dash_orb_position: Vector2
var _is_dashing: bool
var _dead: bool
var _horizontal_direction: int = 1
var _mini: bool:
	set(value):
		_mini = value
		var _mini_scale: Vector2
		if value:
			_mini_scale = MINI_PLAYER_SCALE * WAVE_PLAYER_SCALE if gamemode == Gamemode.WAVE else MINI_PLAYER_SCALE
			create_tween().tween_property(self, "scale", _mini_scale, 0.25) \
				.set_ease(Tween.EASE_OUT) \
				.set_trans(Tween.TRANS_BACK)
		else:
			_mini_scale = Vector2.ONE * WAVE_PLAYER_SCALE if gamemode == Gamemode.WAVE else Vector2.ONE
			create_tween().tween_property(self, "scale", _mini_scale, 0.25) \
				.set_ease(Tween.EASE_OUT) \
				.set_trans(Tween.TRANS_BACK)
var _in_h_block: bool
var _in_j_block: bool
var _is_flying_gamemode: bool
var _speed_multiplier: float = 1.0
var _gravity_multiplier: float = 1.0
var _dual_instance: bool
var _gameplay_rotation_degrees: float = 0.0
var _gameplay_rotation: float
var _last_spider_trail: GDSpiderTrail
var _last_spider_trail_height: float
var _rebound_velocity: float
var _dash_orb_rotation: float

# Bit flags
var _orb_collisions: int
var _pad_collisions: int

func _ready() -> void:
	gamemode = Gamemode.CUBE
	if not _dual_instance:
		LevelManager.player = self

func _physics_process(delta: float) -> void:
	_gameplay_rotation = deg_to_rad(_gameplay_rotation_degrees)
	up_direction = Vector2.UP.rotated(_gameplay_rotation) * sign(_gravity_multiplier)
	_rotate_sprite_degrees(delta)
	_update_wave_trail()
	if gamemode == Gamemode.SWING: _update_swing_fire()
	velocity = _compute_velocity(delta, velocity, _get_direction(), _get_jump_state())
	move_and_slide()
	if _last_spider_trail != null:
		add_child(_last_spider_trail)
		_last_spider_trail._global_position = $Icon/Spider/SpiderCast/SpiderTrailSpawnPoint.global_position if _horizontal_direction > 0 \
			else $Icon/Spider/SpiderCast/SpiderTrailSpawnPointReverse.global_position
		_last_spider_trail._scale_y = abs(_last_spider_trail_height) * sign(_gravity_multiplier)
		_last_spider_trail._scale_x = -_horizontal_direction
		_last_spider_trail = null

func _get_direction() -> int:
	var _direction: int
	if $"../Level".get_child(0).platformer:
		_direction = int(Input.get_axis("move_left", "move_right"))
	else:
		_direction = _horizontal_direction
	return _direction

func _get_jump_state() -> int:
	var jump_state: int
	if Input.is_action_just_pressed("jump") and is_on_floor() and _in_j_block:
		_in_j_block = false
	if _click_buffer_state == ClickBufferState.NOT_HOLDING and Input.is_action_just_pressed("jump") and not (is_on_floor() or is_on_ceiling()) \
		and gamemode != Gamemode.SHIP and gamemode != Gamemode.SWING and gamemode != Gamemode.WAVE:
		_click_buffer_state = ClickBufferState.BUFFERING
	if _click_buffer_state == ClickBufferState.BUFFERING and _orb_collisions != 0:
		_click_buffer_state = ClickBufferState.JUMPING
	if Input.is_action_just_released("jump") or (is_on_floor() or is_on_ceiling()):
		_click_buffer_state = ClickBufferState.NOT_HOLDING
	if _in_j_block:
		jump_state = -1
	elif gamemode == Gamemode.CUBE:
		jump_state = 1 if (Input.is_action_pressed("jump") and (is_on_floor() or is_on_ceiling())) else -1
	elif gamemode == Gamemode.ROBOT:
		if Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_ceiling()):
			$RobotTimer.start(0.25)
		if Input.is_action_just_released("jump"):
			$RobotTimer.stop()
		jump_state = 1 if Input.is_action_pressed("jump") and $RobotTimer.get_time_left() > 0 else -1
	elif gamemode == Gamemode.SHIP or gamemode == Gamemode.WAVE:
		jump_state = 1 if Input.is_action_pressed("jump") else -1
	elif gamemode == Gamemode.UFO or gamemode == Gamemode.SWING:
		jump_state = 1 if Input.is_action_just_pressed("jump") else -1
	elif gamemode == Gamemode.BALL or gamemode == Gamemode.SPIDER:
		jump_state = 1 if (Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_ceiling())) else -1
	return jump_state

func _compute_velocity(_delta: float,
		_previous_velocity: Vector2,
		_direction: int, _jump_state: int,
		) -> Vector2:
	var _velocity: Vector2 = _previous_velocity.rotated(_gameplay_rotation * -1)
	var _speed: Vector2 = SPEED if not _mini else SPEED_MINI
	_is_flying_gamemode = (gamemode == Gamemode.SHIP or gamemode == Gamemode.SWING or gamemode == Gamemode.WAVE)

	if (gamemode == Gamemode.SWING or gamemode == Gamemode.BALL) and _jump_state == 1:
		_gravity_multiplier *= -1

#section Apply Gravity
	if not _is_dashing:
		if gamemode == Gamemode.SHIP:
			_velocity.y += GRAVITY * _delta * _gravity_multiplier * _jump_state * -1 * FLY_GRAVITY_MULTIPLIER
			_velocity.y = clamp(_velocity.y, -FLY_TERMINAL_VELOCITY.y, FLY_TERMINAL_VELOCITY.y)
		elif gamemode == Gamemode.SWING:
			_velocity.y += GRAVITY * _delta * _gravity_multiplier * FLY_GRAVITY_MULTIPLIER
			_velocity.y = clamp(_velocity.y, -FLY_TERMINAL_VELOCITY.y, FLY_TERMINAL_VELOCITY.y)
		elif gamemode == Gamemode.WAVE:
			_velocity.y = SPEED.x * _gravity_multiplier * _jump_state * -1
			if _mini: _velocity.y *= 2
		elif not is_on_floor():
			if gamemode == Gamemode.UFO:
				_velocity.y += GRAVITY * _delta * _gravity_multiplier * UFO_GRAVITY_MULTIPLIER
			else:
				_velocity.y += GRAVITY * _delta * _gravity_multiplier
			_velocity.y = clamp(_velocity.y, -TERMINAL_VELOCITY.y, TERMINAL_VELOCITY.y)
#endsection

	if is_on_floor() and _jump_state == -1 and _pad_collisions == 0:
		_velocity.y = 0.0

#section Pad Collisions
	if gamemode != Gamemode.WAVE:
		if _pad_collisions & GDInteractible.Pad.YELLOW:
			_velocity.y = -_speed.y * (277.0/194.0)
			_pad_collisions &= ~GDInteractible.Pad.YELLOW
		elif _pad_collisions & GDInteractible.Pad.PINK:
			_velocity.y = -_speed.y * (179.0/194.0)
			_pad_collisions &= ~GDInteractible.Pad.PINK
		elif _pad_collisions & GDInteractible.Pad.RED:
			_velocity.y = -_speed.y * (365.0/194.0)
			_pad_collisions &= ~GDInteractible.Pad.RED
		elif _pad_collisions & GDInteractible.Pad.REBOUND:
			_velocity.y = -_rebound_velocity
			_pad_collisions &= ~GDInteractible.Pad.REBOUND
	# These pads are supposed to work with the wave
	if _pad_collisions & GDInteractible.Pad.SPIDER:
		_gravity_multiplier = Vector2.UP.rotated($Icon/Spider/SpiderCast.rotation).y
		_velocity.y = _get_spider_velocity_delta() * 1/_delta
		_last_spider_trail_height = abs(_get_spider_velocity_delta()/_last_spider_trail.SPIDER_TRAIL_HEIGHT)
		_pad_collisions &= ~GDInteractible.Pad.SPIDER
	elif _pad_collisions & GDInteractible.Pad.BLUE:
		_gravity_multiplier *= -1
		_velocity.y = _speed.y * (137.0/194.0) * _gravity_multiplier if not gamemode == Gamemode.WAVE else 0.0
		_pad_collisions &= ~GDInteractible.Pad.BLUE
#endsection

	# Handle jump.
	if _jump_state == 1 and _pad_collisions == 0 and _orb_collisions == 0:
		if _is_flying_gamemode:
			pass
		elif gamemode == Gamemode.SPIDER:
			_gravity_multiplier *= -1
			_velocity.y = _get_spider_velocity_delta() * 1/_delta
			_last_spider_trail_height = abs(_get_spider_velocity_delta()/_last_spider_trail.SPIDER_TRAIL_HEIGHT)
		elif gamemode == Gamemode.BALL:
			_velocity.y = _speed.y * _gravity_multiplier * 0.5
		elif gamemode == Gamemode.ROBOT:
			_velocity.y = SPEED.x * _gravity_multiplier * -1
		else:
			_velocity.y = -_speed.y * _gravity_multiplier

	if _is_dashing:
		$DashFlame.visible = true
		$DashFlame.rotation = _dash_orb_rotation
		if (is_on_floor() and sin(_dash_orb_rotation) > 0) or (is_on_ceiling() and sin(_dash_orb_rotation) < 0):
			_velocity.y = 0
		else:
			_velocity.y = tan(_dash_orb_rotation - _gameplay_rotation) * _speed.x
		if Input.is_action_just_released("jump"):
			_is_dashing = false
			$DashFlame.hide()

	if _direction:
		_velocity.x = _direction * _speed.x * int(get_parent().has_level_started)
	else:
		_velocity.x = move_toward(_velocity.x, 0, _speed.x)

#section orbs
	if _orb_collisions != 0 and (
		_click_buffer_state == ClickBufferState.JUMPING
		or (_jump_state == 1 and not _is_flying_gamemode)
		or (Input.is_action_just_pressed("jump") and _is_flying_gamemode)
		):
		emit_signal("orb_clicked")
		_click_buffer_state = ClickBufferState.BUFFER_USED
		if _reverse_direction_buffer != 0:
			_horizontal_direction = _reverse_direction_buffer
			_reverse_direction_buffer = 0
		if gamemode != Gamemode.WAVE:
			if _orb_collisions & GDInteractible.Orb.YELLOW:
				_velocity.y = -_speed.y * (191.0/194.0)
				_orb_collisions &= ~GDInteractible.Orb.YELLOW
			if _orb_collisions & GDInteractible.Orb.PINK:
				_velocity.y = -_speed.y * (137.0/194.0)
				_orb_collisions &= ~GDInteractible.Orb.PINK
			if _orb_collisions & GDInteractible.Orb.RED:
				_velocity.y = -_speed.y * (268.0/194.0)
				_orb_collisions &= ~GDInteractible.Orb.RED
			if _orb_collisions & GDInteractible.Orb.BLACK:
				_velocity.y = -_speed.y * -(260.0/194.0)
				_orb_collisions &= ~GDInteractible.Orb.BLACK
			if _orb_collisions & GDInteractible.Orb.REBOUND:
				_velocity.y = -_rebound_velocity
				_orb_collisions &= ~GDInteractible.Orb.REBOUND
		# These orbs are supposed to work with the wave
		if _orb_collisions & GDInteractible.Orb.SPIDER:
			_gravity_multiplier *= -1 * $Icon/Spider/SpiderCast.scale.y
			# _gravity_multiplier *= $Icon/Spider/SpiderCast.scale.y
			_velocity.y = _get_spider_velocity_delta() * 1/_delta
			_last_spider_trail_height = abs(_get_spider_velocity_delta()/_last_spider_trail.SPIDER_TRAIL_HEIGHT)
			_in_j_block = true
			_orb_collisions &= ~GDInteractible.Orb.SPIDER
		if _orb_collisions & GDInteractible.Orb.BLUE:
			_gravity_multiplier *= -1
			_velocity.y = _speed.y * (137.0/194.0) * _gravity_multiplier if not gamemode == Gamemode.WAVE else 0.0
			_pad_collisions &= ~GDInteractible.Orb.BLUE
		if _orb_collisions & GDInteractible.Orb.GREEN:
			_gravity_multiplier *= -1
			_velocity.y = -_speed.y * (191.0/194.0) * _gravity_multiplier if not gamemode == Gamemode.WAVE else 0.0
			_pad_collisions &= ~GDInteractible.Orb.GREEN
		if _orb_collisions & GDInteractible.Orb.DASH_GREEN:
			var _last_dash_boom = DASH_BOOM.instantiate()
			_last_dash_boom.position = to_local(_dash_orb_position)
			add_child(_last_dash_boom)
			_is_dashing = true
			_orb_collisions &= ~GDInteractible.Orb.DASH_GREEN
		if _orb_collisions & GDInteractible.Orb.DASH_MAGENTA:
			var _last_dash_boom = DASH_BOOM.instantiate()
			_last_dash_boom.position = to_local(_dash_orb_position)
			add_child(_last_dash_boom)
			_gravity_multiplier *= -1
			_is_dashing = true
			_orb_collisions &= ~GDInteractible.Orb.DASH_MAGENTA
		if _orb_collisions & GDInteractible.Orb.TELEPORT:
			emit_signal("teleported")
			_orb_collisions &= ~GDInteractible.Orb.TELEPORT
#endsection

	_velocity.y *= int(get_parent().has_level_started)

	if not _dead:
		return _velocity.rotated(_gameplay_rotation)
	else:
		return Vector2.ZERO

func _rotate_sprite_degrees(delta: float):
#section cube
	$Icon/Cube.scale.y = 1.0
	if _horizontal_direction != 0:
		$Icon/Cube.scale.x = _horizontal_direction
	if not _is_dashing:
		if not is_on_floor() and not is_on_ceiling():
			$Icon/Cube.rotation_degrees += delta * _gravity_multiplier * 400 * _get_direction()
		else:
			$Icon/Cube.rotation_degrees = lerpf($Icon/Cube.rotation_degrees, snapped($Icon/Cube.rotation_degrees, 90), 0.5)
	else:
		$Icon/Cube.rotation_degrees += delta * 800 * _get_direction()
#endsection
#section ship/swing
	$Icon/Ship.scale.y = sign(_gravity_multiplier)
	$Icon/Swing.scale.y = 1.0
	if _horizontal_direction != 0:
		$Icon/Ship.scale.x = _horizontal_direction
		$Icon/Swing.scale.x = _horizontal_direction
	if not _is_dashing:
		if not is_on_floor() and not is_on_ceiling():
			$Icon/Ship.rotation_degrees = lerpf($Icon/Ship.rotation, velocity.rotated(-_gameplay_rotation).y * delta * _get_direction() * 3, 0.5)
			$Icon/Swing.rotation_degrees = lerpf($Icon/Swing.rotation, velocity.rotated(-_gameplay_rotation).y * delta * _get_direction() * 3, 0.5)
		else:
			$Icon/Ship.rotation_degrees = lerpf($Icon/Ship.rotation_degrees, 0.0, 0.5)
			$Icon/Swing.rotation_degrees = lerpf($Icon/Swing.rotation_degrees, 0.0, 0.5)
	else:
		$Icon/Ship.rotation = lerpf($Icon/Ship.rotation, _dash_orb_rotation, 0.5)
		$Icon/Swing.rotation = lerpf($Icon/Swing.rotation, _dash_orb_rotation, 0.5)
#endsection
#section wave
	$Icon/Wave.scale.y = 1.0
	if _horizontal_direction != 0:
		$Icon/Wave.scale.x = _horizontal_direction
	if not _is_dashing:
		if not is_on_floor() and not is_on_ceiling():
			if velocity.rotated(-_gameplay_rotation).x != 0.0:
				if not _mini:
					$Icon/Wave.rotation_degrees = lerpf($Icon/Wave.rotation_degrees, 45.0 * -_get_jump_state(), 0.25)
				else:
					$Icon/Wave.rotation_degrees = lerpf($Icon/Wave.rotation_degrees, 60.0 * -_get_jump_state(), 0.25)
			else:
				$Icon/Wave.rotation_degrees = lerpf($Icon/Wave.rotation_degrees, 90.0 * -_get_jump_state(), 0.25)
		else:
			$Icon/Wave.rotation_degrees = lerpf($Icon/Wave.rotation_degrees, 0.0, 0.5)
	else:
		$Icon/Wave.rotation = lerpf($Icon/Wave.rotation, _dash_orb_rotation, 0.5)
#endsection
#section ufo
	$Icon/UFO.scale.y = sign(_gravity_multiplier)
	if _horizontal_direction != 0:
		$Icon/UFO.scale.x = _horizontal_direction
	if not is_on_floor() and not is_on_ceiling():
		$Icon/UFO.rotation_degrees = velocity.rotated(-_gameplay_rotation).y * delta * 0.2
	else:
		$Icon/UFO.rotation_degrees = lerpf($Icon/UFO.rotation_degrees, 0.0, 0.5)
#endsection
#section ball
	$Icon/Ball.scale.y = 1.0
	if _horizontal_direction != 0:
		$Icon/Ball.scale.x = _horizontal_direction
	$Icon/Ball.rotation_degrees += delta * _gravity_multiplier * 600
#endsection
#section spider/robot
	$Icon/Spider.scale.y = sign(_gravity_multiplier)
	$Icon/Robot.scale.y = sign(_gravity_multiplier)
	if _horizontal_direction != 0:
		$Icon/Spider.scale.x = _horizontal_direction
		$Icon/Robot.scale.x = _horizontal_direction
#endsection

func _update_swing_fire() -> void:
	if _gravity_multiplier < 0.0:
		$Icon/Swing/FireBoostTop.position = $Icon/Swing/FireBoostTop.position.lerp(Vector2.ZERO, 0.2)
		$Icon/Swing/FireBoostBottom.position = $Icon/Swing/FireBoostBottom.position.lerp(Vector2(-54.0, 63.0), 0.2)
	else:
		$Icon/Swing/FireBoostTop.position = $Icon/Swing/FireBoostTop.position.lerp(Vector2(-54.0, -63.0), 0.2)
		$Icon/Swing/FireBoostBottom.position = $Icon/Swing/FireBoostBottom.position.lerp(Vector2.ZERO, 0.2)

func _update_wave_trail() -> void:
	if not _mini:
		$WaveTrail.width = lerpf($WaveTrail.width, WAVE_TRAIL_WIDTH, 0.25)
		$WaveTrail2.width = lerpf($WaveTrail2.width, WAVE_TRAIL_WIDTH * 0.5, 0.25)
	else:
		$WaveTrail.width = lerpf($WaveTrail.width, WAVE_TRAIL_WIDTH * MINI_PLAYER_SCALE.y, 0.25)
		$WaveTrail2.width = lerpf($WaveTrail2.width, WAVE_TRAIL_WIDTH * MINI_PLAYER_SCALE.y * 0.5, 0.25)
	# $WaveTrail.visible = gamemode == Gamemode.WAVE
	# $WaveTrail2.visible = gamemode == Gamemode.WAVE
	if gamemode == Gamemode.WAVE:
		$WaveTrail.length = lerpf($WaveTrail.length, 50.0, 0.2)
		$WaveTrail2.length = lerpf($WaveTrail.length, 50.0, 0.2)
	else:
		$WaveTrail.length = 0
		$WaveTrail2.length = 0
		if $WaveTrail.get_point_count() > $WaveTrail.length:
			for i in range(2):
				if $WaveTrail.get_point_count() != 0:
					$WaveTrail.remove_point($WaveTrail.get_point_count() - 1)
					$WaveTrail2.remove_point($WaveTrail2.get_point_count() - 1)

func _get_spider_velocity_delta() -> float:
	var _target_position = $Icon/Spider/SpiderCast.get_collision_point(0)
	var _spider_velocity_delta: float = abs((_target_position - position).rotated(-_gameplay_rotation).y)
	_spider_velocity_delta -= $GroundCollider.shape.size.y/2 * scale.y
	_last_spider_trail = SPIDER_TRAIL.instantiate()
	return _spider_velocity_delta * _gravity_multiplier

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
	$DeathAnimator.play("DeathAnimation")

func _on_kill_collider_hazard_body_entered(_body:Node2D) -> void:
	$DeathAnimator.play("DeathAnimation")
