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

@export var gamemode: Gamemode:
	set(value):
		gamemode = value
		for icon in $Icon.get_children():
			if icon.gamemode != value: icon.hide()
			else: icon.show()

var _dead: bool
var _reverse: bool
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
var _is_in_h_block: bool
var _speed_multiplier: float = 1.0
var _gravity_multiplier: float = 1.0
var _dual_instance: bool
var _gameplay_rotation_degrees: float = 0.0
var _gameplay_rotation: float

# Bit flags
var _orb_collisions: int
var _pad_collisions: int

func _ready() -> void:
	gamemode = Gamemode.CUBE
	if not _dual_instance:
		LevelManager.player = self

func _physics_process(delta: float) -> void:
	_gameplay_rotation = deg_to_rad(_gameplay_rotation_degrees)
	up_direction = Vector2.UP.rotated(_gameplay_rotation)
	$Icon.rotation_degrees = _rotate_sprite_degrees(delta, $Icon.rotation_degrees)
	_update_wave_trail()
	if gamemode == Gamemode.SWING: _update_swing_fire()
	velocity = _compute_velocity(delta, velocity, _get_direction(), _get_jump_state())
	move_and_slide()

func _get_direction() -> int:
	var _direction: int
	if $"../Level".get_child(0).platformer:
		_direction = int(Input.get_axis("move_left", "move_right"))
	else:
		_direction = -1 if _reverse else 1
	return _direction

func _get_jump_state() -> int:
	var jump_state: int
	if gamemode == Gamemode.CUBE:
		jump_state = 1 if Input.is_action_pressed("jump") and is_on_floor() else -1
	elif gamemode == Gamemode.ROBOT:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			$RobotTimer.start(0.25)
		if Input.is_action_just_released("jump"):
			$RobotTimer.stop()
		jump_state = 1 if Input.is_action_pressed("jump") and $RobotTimer.get_time_left() > 0 else -1
	elif gamemode == Gamemode.SHIP or gamemode == Gamemode.WAVE:
		jump_state = 1 if Input.is_action_pressed("jump") else -1
	elif gamemode == Gamemode.UFO or gamemode == Gamemode.SWING:
		jump_state = 1 if Input.is_action_just_pressed("jump") else -1
	elif gamemode == Gamemode.BALL or gamemode == Gamemode.SPIDER:
		jump_state = 1 if Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_ceiling()) else -1
	return jump_state

func _compute_velocity(_delta: float,
		_previous_velocity: Vector2,
		_direction: int, _jump_state: int,
		) -> Vector2:
	var _velocity: Vector2 = _previous_velocity.rotated(_gameplay_rotation * -1)
	var _speed: Vector2 = SPEED if not _mini else SPEED_MINI
	var _is_flying_gamemode: bool = (gamemode == Gamemode.SHIP or gamemode == Gamemode.SWING or gamemode == Gamemode.WAVE)

	if (gamemode == Gamemode.SWING or gamemode == Gamemode.BALL) and _jump_state == 1:
		_gravity_multiplier *= -1

#section Apply Gravity
	if gamemode == Gamemode.SHIP:
		_velocity.y += GRAVITY * _delta * _gravity_multiplier * _jump_state * -1 * FLY_GRAVITY_MULTIPLIER
		_velocity.y = clamp(_velocity.y, -FLY_TERMINAL_VELOCITY.y, FLY_TERMINAL_VELOCITY.y)
		up_direction.y = _jump_state
	elif gamemode == Gamemode.SWING:
		_velocity.y += GRAVITY * _delta * _gravity_multiplier * FLY_GRAVITY_MULTIPLIER
		_velocity.y = clamp(_velocity.y, -FLY_TERMINAL_VELOCITY.y, FLY_TERMINAL_VELOCITY.y)
		up_direction.y = _gravity_multiplier * -1
	elif gamemode == Gamemode.WAVE:
		_velocity.y = SPEED.x * _gravity_multiplier * _jump_state * -1
		if _mini: _velocity.y *= 2
		up_direction.y = _gravity_multiplier * -1
	elif not is_on_floor():
		up_direction.y = _gravity_multiplier * -1
		if gamemode == Gamemode.UFO:
			_velocity.y += GRAVITY * _delta * _gravity_multiplier * UFO_GRAVITY_MULTIPLIER
		elif gamemode == Gamemode.CUBE or gamemode == Gamemode.BALL or gamemode == Gamemode.ROBOT:
			_velocity.y += GRAVITY * _delta * _gravity_multiplier
		_velocity.y = clamp(_velocity.y, -TERMINAL_VELOCITY.y, TERMINAL_VELOCITY.y)
#endsection

	if is_on_floor() and _jump_state == -1:
		_velocity.y = 0.0

	# Handle jump.
	if _jump_state == 1:
		if _orb_collisions & GDInteractible.Orb.YELLOW:
			pass
		elif _is_flying_gamemode:
			pass
		elif gamemode == Gamemode.BALL:
			_velocity.y = _speed.y * _gravity_multiplier * 0.5
			up_direction.y *= -1
		elif gamemode == Gamemode.ROBOT:
			_velocity.y = SPEED.x * _gravity_multiplier * -1
		else:
			_velocity.y = -_speed.y
	if _direction:
		_velocity.x = _direction * _speed.x * int(get_parent().has_level_started)
	else:
		_velocity.x = move_toward(_velocity.x, 0, _speed.x)

	_velocity.y *= int(get_parent().has_level_started)

	if not _dead:
		return _velocity.rotated(_gameplay_rotation)
	else:
		return Vector2.ZERO

func _rotate_sprite_degrees(delta: float, previous_rotation_degrees: float) -> float:
	if gamemode != Gamemode.SWING:
		$Icon.scale.y = _gravity_multiplier
	else:
		$Icon.scale.y = 1.0
	if gamemode == Gamemode.CUBE:
		if not is_on_floor():
			return previous_rotation_degrees + delta * _gravity_multiplier * 400
		else:
			return lerpf(previous_rotation_degrees, snapped(previous_rotation_degrees, 90), 0.5)
	elif gamemode == Gamemode.SHIP or gamemode == Gamemode.SWING:
		if not is_on_floor():
			return velocity.rotated(-_gameplay_rotation).y * delta
		else:
			return lerpf(previous_rotation_degrees, 0.0, 0.5)
	elif gamemode == Gamemode.WAVE:
		if not is_on_floor():
			if velocity.rotated(-_gameplay_rotation).x != 0.0:
				if not _mini:
					return lerpf(previous_rotation_degrees, 45.0 * -_get_jump_state(), 0.25)
				else:
					return lerpf(previous_rotation_degrees, 60.0 * -_get_jump_state(), 0.25)
			else:
				return lerpf(previous_rotation_degrees, 90.0 * -_get_jump_state(), 0.25)
		else:
			return lerpf(previous_rotation_degrees, 0.0, 0.5)
	elif gamemode == Gamemode.UFO:
		if not is_on_floor():
			return velocity.rotated(-_gameplay_rotation).y * delta * 0.2
		else:
			return lerpf(previous_rotation_degrees, 0.0, 0.5)
	elif gamemode == Gamemode.BALL:
		return previous_rotation_degrees + delta * _gravity_multiplier * 600
	else:
		return previous_rotation_degrees

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
				$WaveTrail.remove_point($WaveTrail.get_point_count() - 1)
				$WaveTrail2.remove_point($WaveTrail2.get_point_count() - 1)

func _set_spider_shapecast_rotation(new_rotation: float) -> void:
	pass

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
