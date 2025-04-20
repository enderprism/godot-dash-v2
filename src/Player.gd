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
const PLATFORMER_ACCELERATION := 5.0
const ENSURE_VELOCITY_REDIRECT_SAFE_MARGIN := 2.0
#endregion

#region Bit Flags
const EVALUATE_CLICK_BUFFER := 1
#endregion

@export var displayed_gamemode: Gamemode:
	set(value):
		displayed_gamemode = value
		for icon in $Icon.get_children():
			if icon.gamemode != value:
				icon.hide()
			elif (not LevelManager.platformer and speed_multiplier > 0.0) and icon.platformer == IconGamemodeProp.PlatformerState.PLATFORMER_ONLY:
				icon.hide()
			elif (LevelManager.platformer or speed_multiplier == 0.0) and icon.platformer == IconGamemodeProp.PlatformerState.SIDESCROLLER_ONLY:
				icon.hide()
			else:
				icon.show()
@export var internal_gamemode: Gamemode
@export var default_collider: RectangleShape2D
@export var slope_collider: CircleShape2D

# Public
var rebound_velocity: float
var gameplay_rotation_degrees: float = 0.0
var gameplay_rotation: float:
	get():
		return deg_to_rad(gameplay_rotation_degrees)
	set(value):
		gameplay_rotation_degrees = rad_to_deg(value)
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
var last_collision: KinematicCollision2D
var floor_angle_history: Array[float]
var floor_angle_average: float
var sprite_floor_angle: float
var dual_index: int

# Queues
var orb_queue: Array[OrbInteractable]
var pad_queue: Array[PadInteractable]

# Private
var _spider_jump_invulnerability_frames: int = 0
var _click_buffer_state: ClickBufferState
var _dead: bool
var _is_flying_gamemode: bool
var _last_spider_trail: SpiderTrail
var _last_spider_trail_height: float
var _deferred_velocity_redirect: bool
var _spider_state_machine: AnimationNodeStateMachinePlayback
var _spider_animation_tree: AnimationTree


func _ready() -> void:
	platform_on_leave = PlatformOnLeave.PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY if not LevelManager.platformer else PlatformOnLeave.PLATFORM_ON_LEAVE_ADD_VELOCITY
	dash_control = null
	_spider_animation_tree = $Icon/Spider/SpiderStateMachine
	_spider_state_machine = _spider_animation_tree["parameters/playback"]
	internal_gamemode = Gamemode.CUBE
	displayed_gamemode = Gamemode.CUBE
	if dual_index == 0:
		LevelManager.player = self
	else:
		LevelManager.player_duals.append(self)
	apply_floor_snap()


func _physics_process(delta: float) -> void:
	if _dead or not LevelManager.level_playing:
		return
	
	up_direction = Vector2.UP.rotated(gameplay_rotation) * sign(gravity_multiplier)
	velocity = _compute_velocity(delta, velocity, get_direction(), _get_jump_state(EVALUATE_CLICK_BUFFER))
	if not $SlopeShapecast.is_colliding() and $GroundCollider.shape is CircleShape2D:
		$GroundCollider.shape = default_collider
		$SolidOverlapCheck/SolidOverlapCheckCollider.shape = default_collider
		$Icon/Spider/SpiderCast.shape = default_collider
	last_collision = move_and_collide(velocity * delta, true)
	floor_snap_length = 0.0 if LevelManager.platformer and internal_gamemode == Gamemode.WAVE else LevelManager.CELL_SIZE * 0.5 * speed_multiplier
	_handle_collision(last_collision)
	move_and_slide()
	_rotate_sprite_degrees(delta)
	_update_wave_trail(delta)
	if _last_spider_trail != null:
		add_child(_last_spider_trail)
		_last_spider_trail.trail_global_position = $Icon/Spider/SpiderCast/SpiderTrailSpawnPoint.global_position if horizontal_direction > 0 \
			else $Icon/Spider/SpiderCast/SpiderTrailSpawnPointReverse.global_position
		_last_spider_trail.displayed_scale_y = abs(_last_spider_trail_height) * sign(gravity_multiplier)
		_last_spider_trail.displayed_scale_x = -horizontal_direction
		_last_spider_trail = null
	#region 0x speed portal position nudge
	if speed_0_portal_control:
		var rotation_local_global_position = global_position.rotated(-gameplay_rotation)
		var rotation_local_portal_global_position = speed_0_portal_control.parent.global_position.rotated(-gameplay_rotation)
		var rotation_local_velocity = velocity.rotated(-gameplay_rotation)
		global_position = Vector2(
			rotation_local_global_position.lerp(rotation_local_portal_global_position, 0.3 * delta * 60).x,
			rotation_local_global_position.y
			).rotated(gameplay_rotation)
		velocity = Vector2(
			0.0,
			rotation_local_velocity.y
			).rotated(gameplay_rotation)
		if is_equal_approx(rotation_local_global_position.x, rotation_local_portal_global_position.x):
			displayed_gamemode = displayed_gamemode
			speed_0_portal_control = null
	#endregion
	if displayed_gamemode == Gamemode.SPIDER: _update_spider_state_machine()
	if displayed_gamemode == Gamemode.SWING: _update_swing_fire(delta)


func _handle_collision(collision: KinematicCollision2D) -> void:
	if not collision:
		return
	var collision_angle: float = collision.get_angle(up_direction)
	var restricted_collision_angle: float = pingpong(collision_angle, PI/2) * sign(collision_angle)
	var is_floor: bool = restricted_collision_angle <= deg_to_rad(10.0)
	var is_ceiling: bool = restricted_collision_angle >= floor_max_angle
	if not LevelManager.platformer and not is_floor:
		if collision.get_collider().collision_layer & 1 << 1:
			collision.get_collider().collision_layer = 1 << 9
			collision.get_collider().get_node("Hitbox").debug_color.s = 0.0 # DEBUG: Hardcoded name for hitbox color
	if not (is_floor or is_ceiling):
		$GroundCollider.shape = slope_collider
		$Icon/Spider/SpiderCast.shape = slope_collider
		$SolidOverlapCheck/SolidOverlapCheckCollider.shape = slope_collider


func get_floor_angle_signed(last_slide: bool) -> float:
	var floor_normal: Vector2
	if last_slide:
		floor_normal = get_last_slide_collision().get_normal()
	else:
		floor_normal = get_floor_normal()
	var floor_angle: float
	if _is_flying_gamemode and is_on_ceiling() and _get_jump_state() == 1:
		var local_up_direction: Vector2 = Vector2.DOWN.rotated(gameplay_rotation) * sign(gravity_multiplier)
		floor_angle = snappedf(rad_to_deg(floor_normal.angle_to(local_up_direction)), 0.01)
	else:
		floor_angle = snappedf(rad_to_deg(floor_normal.angle_to(up_direction)), 0.01)
	# Iron out jittery angles
	if abs(floor_angle - floor_angle_average) > 0.5:
		floor_angle_history.clear()
	if len(floor_angle_history) > 10:
		floor_angle_history.pop_front()
	floor_angle_history.append(floor_angle)
	floor_angle_average = ArrayUtils.transform(floor_angle_history, ArrayUtils.Transformation.MEAN)
	floor_angle_average = snappedf(floor_angle_average, 0.01)
	if is_equal_approx(abs(floor_angle), 90.0):
		return 0.0
	return deg_to_rad(floor_angle)


func get_direction() -> int:
	var direction: int
	if LevelManager.platformer:
		direction = int(Input.get_axis("move_left", "move_right"))
		if direction != 0:
			horizontal_direction = direction
	else:
		direction = horizontal_direction
	return direction


func _get_jump_state(options: int = 0) -> int:
	var jump_state: int
	if Input.is_action_just_pressed("jump") and is_on_floor() and jump_hold_disabled:
		jump_hold_disabled = false
	if options & EVALUATE_CLICK_BUFFER:
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
	if get_viewport().gui_get_hovered_control() != null:
		if get_viewport().gui_get_hovered_control().name == "EditorViewport":
			return jump_state
		else:
			return -1
	return jump_state


func _compute_velocity(delta: float,
		previous_velocity: Vector2,
		direction: int, jump_state: int) -> Vector2:
	var _velocity: Vector2 = previous_velocity.rotated(-gameplay_rotation)
	_is_flying_gamemode = (internal_gamemode == Gamemode.SHIP or internal_gamemode == Gamemode.SWING or internal_gamemode == Gamemode.WAVE)
	
	if _spider_jump_invulnerability_frames > 0: _spider_jump_invulnerability_frames -= 1
	
	#region Slope physics
	var slope_velocity: Vector2
	if $GroundCollider.shape is CircleShape2D and get_last_slide_collision() != null:
		var floor_angle := get_floor_angle_signed(true)
		# 90° collision warp prevention
		if pingpong(floor_angle, PI/2) < floor_max_angle:
			slope_velocity.y = tan(-floor_angle) * abs(_velocity.x) * direction
	#endregion

	if (internal_gamemode == Gamemode.SWING or internal_gamemode == Gamemode.BALL) and jump_state == 1 and orb_queue.is_empty():
		gravity_multiplier *= -1

	$GroundCollider.rotation = gameplay_rotation
	$SolidOverlapCheck.rotation = gameplay_rotation
	$KillColliderSolid.rotation = gameplay_rotation
	$KillColliderRectangularHazard.rotation = gameplay_rotation
	$KillColliderCircularHazard.rotation = gameplay_rotation
	$GroundRaycast.rotation = gameplay_rotation
	$GroundRaycast.scale.y = gravity_multiplier
	$SlopeShapecast.rotation = gameplay_rotation
	$SlopeShapecast.scale.y = gravity_multiplier

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
			# _velocity.y = clamp(_velocity.y, -TERMINAL_VELOCITY.y, TERMINAL_VELOCITY.y)
	#endregion
	
	var flying_gamemode_slope_boost: bool = _is_flying_gamemode and (
		(is_on_ceiling() and jump_state >= 0) or
		(is_on_floor() and get_last_slide_collision() != null and get_floor_angle_signed(true) != 0.0 and get_direction() != 0 and jump_state == 1))
	if ((is_on_floor() and jump_state <= 0 and not _deferred_velocity_redirect) or flying_gamemode_slope_boost) and pad_queue.is_empty():
		_velocity.y = slope_velocity.y

	#region Apply pads velocity
	if not pad_queue.is_empty():
		var colliding_pad: PadInteractable = pad_queue.pop_front()
		for component in colliding_pad.components:
			if internal_gamemode != Gamemode.WAVE and (component is JumpBoostComponent or (component is ReboundComponent and (not is_on_floor() or _deferred_velocity_redirect))):
				_velocity.y = component.get_velocity(self)
				if displayed_gamemode == Gamemode.SPIDER:
					_spider_state_machine.travel("jump")
			elif component is SpiderDashComponent:
				component.set_dash_flip_state(self)
				gravity_multiplier *= -1
				position += Vector2.DOWN.rotated(gameplay_rotation) * _get_spider_velocity_delta()
				jump_hold_disabled = true
	#endregion

	#region Handle jump.
	if jump_state == 1 and pad_queue.is_empty() and orb_queue.is_empty():
		if _is_flying_gamemode:
			pass
		elif internal_gamemode == Gamemode.SPIDER:
			gravity_multiplier *= -1
			position += Vector2.DOWN.rotated(gameplay_rotation) * _get_spider_velocity_delta()
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
			_velocity.x = direction * speed.x * speed_multiplier * int(LevelManager.level_playing)
		else:
			_velocity.x = 0
	else:
		if direction:
			_velocity.x = move_toward(
				_velocity.x,
				direction * speed.x * speed_multiplier * int(LevelManager.level_playing),
				speed.x * delta * speed_multiplier * PLATFORMER_ACCELERATION * int(LevelManager.level_playing))
		else:
			_velocity.x = move_toward(
				_velocity.x,
				0.0,
				speed.x * delta * speed_multiplier * PLATFORMER_ACCELERATION * int(LevelManager.level_playing))

	
	var visual_gameplay_rotation_degrees: float = round(gameplay_rotation_degrees - LevelManager.player_camera.global_rotation_degrees)
	var gameplay_rotation_in_180_quadrant: bool = abs(visual_gameplay_rotation_degrees) > 135.0 and abs(visual_gameplay_rotation_degrees) < 225.0
	var flipped_controls_in_90_quadrant: bool = gravity_multiplier < 0 and abs(visual_gameplay_rotation_degrees) > 45.0 and abs(visual_gameplay_rotation_degrees) < 135.0

	if LevelManager.platformer and abs(_velocity.x) < 10.0 and (gameplay_rotation_in_180_quadrant or flipped_controls_in_90_quadrant):
		gameplay_rotation_degrees = wrapf((abs(gameplay_rotation_degrees) - 180.0) * signf(gameplay_rotation_degrees), -180.0, 180.0)
		gravity_multiplier *= -1
	
	#region Apply orbs velocity
	if not orb_queue.is_empty() and (
			_click_buffer_state == ClickBufferState.JUMPING
			or (jump_state == 1 and not _is_flying_gamemode and not _click_buffer_state == ClickBufferState.BUFFER_USED)
			or (Input.is_action_just_pressed("jump") and _is_flying_gamemode)):
		var colliding_orb: OrbInteractable = orb_queue.pop_front()
		_click_buffer_state = ClickBufferState.BUFFER_USED
		colliding_orb.pressed.emit(self)
		for component in colliding_orb.components:
			if internal_gamemode != Gamemode.WAVE and (component is JumpBoostComponent or component is ReboundComponent):
				_velocity.y = component.get_velocity(self)
				if displayed_gamemode == Gamemode.SPIDER:
					_spider_state_machine.travel("jump")
			elif component is SpiderDashComponent:
				component.set_dash_flip_state(self)
				gravity_multiplier = -sign($Icon/Spider/SpiderCast.scale.y)
				position += Vector2.DOWN.rotated(gameplay_rotation) * _get_spider_velocity_delta()
				jump_hold_disabled = true
		if not colliding_orb.single_usage:
			orb_queue.append(colliding_orb)
	#endregion

	#region Dash orb velocity
	if dash_control:
		_velocity = dash_control.path.get_velocity(self)
		if Input.is_action_just_released("jump"):
			stop_dash()
	#endregion

	_deferred_velocity_redirect = _ensure_velocity_redirect(delta, _velocity.rotated(gameplay_rotation))

	return _velocity.rotated(gameplay_rotation)


## Ensure velocity redirection can happen and the vertical velocity isn't reset by hitting the floor.
func _ensure_velocity_redirect(delta: float, global_velocity: Vector2) -> bool:
	var down_direction_snapped_velocity := global_velocity.rotated(global_velocity.angle_to(up_direction.rotated(PI)))
	$EnsureVelocityRedirect.shape = $GroundCollider.shape
	$EnsureVelocityRedirect.target_position = down_direction_snapped_velocity * delta * ENSURE_VELOCITY_REDIRECT_SAFE_MARGIN
	$EnsureVelocityRedirect.force_shapecast_update()
	if not $EnsureVelocityRedirect.is_colliding():
		return false
	for i in $EnsureVelocityRedirect.get_collision_count():
		var collided_area := $EnsureVelocityRedirect.get_collider(i) as Area2D
		if not collided_area is Interactable:
			return false
		for component in collided_area.components:
			return (component is ReboundComponent and not is_on_floor()) or (component is TeleportComponent and component.redirect_velocity)
	return false


func _rotate_sprite_degrees(delta: float):
	if $GroundCollider.shape is CircleShape2D:
		if get_floor_normal() != Vector2.ZERO:
			if not is_zero_approx(get_floor_angle_signed(false)):
				sprite_floor_angle = lerp_angle(
						sprite_floor_angle,
						-get_floor_angle_signed(false) + gameplay_rotation,
						delta * 60 * ICON_LERP_FACTOR)
		elif last_collision != null and last_collision.get_normal() != Vector2.ZERO:
			var ceiling_slide_rotation := PI if -last_collision.get_normal().angle_to(up_direction) < 0.0 else 0.0
			sprite_floor_angle = lerp_angle(
					sprite_floor_angle,
					-last_collision.get_normal().angle_to(up_direction) + gameplay_rotation + ceiling_slide_rotation,
					delta * 60 * ICON_LERP_FACTOR)
	else:
		sprite_floor_angle = lerp_angle(sprite_floor_angle, gameplay_rotation, delta * 60 * ICON_LERP_FACTOR)
	#region cube
	$Icon/Cube.scale.y = 1.0
	if horizontal_direction != 0:
		$Icon/Cube.scale.x = horizontal_direction
	if not dash_control:
		if not is_on_floor() and not is_on_ceiling() and speed_multiplier > 0.0:
			$Icon/Cube.rotation_degrees += delta * gravity_multiplier * 400 * get_direction()
		else:
			$Icon/Cube.rotation = lerpf(
					$Icon/Cube.rotation,
					snapped($Icon/Cube.rotation + sprite_floor_angle, PI) - sprite_floor_angle,
					ICON_LERP_FACTOR * delta * 60)
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
			var target_rotation_degrees := gameplay_rotation_degrees + velocity.rotated(-gameplay_rotation).y * delta * get_direction() * (7.5/speed_multiplier)
			$Icon/Ship.rotation_degrees = lerpf(
					$Icon/Ship.rotation_degrees,
					target_rotation_degrees,
					ICON_LERP_FACTOR * delta * 60)
			$Icon/Swing.rotation_degrees = lerpf(
					$Icon/Swing.rotation_degrees,
					target_rotation_degrees,
					ICON_LERP_FACTOR * delta * 60)
		else:
			$Icon/Ship.rotation = lerp_angle($Icon/Ship.rotation, sprite_floor_angle, ICON_LERP_FACTOR * delta * 60)
			$Icon/Swing.rotation = lerp_angle($Icon/Swing.rotation, sprite_floor_angle, ICON_LERP_FACTOR * delta * 60)
	else:
		$Icon/Ship.rotation = lerpf($Icon/Ship.rotation, dash_control.angle * get_direction(), ICON_LERP_FACTOR)
		$Icon/Swing.rotation = lerpf($Icon/Swing.rotation, dash_control.angle * get_direction(), ICON_LERP_FACTOR)
	#endregion
	#region wave
	$Icon/Wave.rotation = lerpf($Icon/Wave.rotation, gameplay_rotation, ICON_LERP_FACTOR * delta * 60)
	$Icon/Wave.scale.y = 1.0
	if get_direction() != 0 or _get_jump_state() != 0:
		$Icon/Wave.set_meta("last_8_direction", Vector2(get_direction(), _get_jump_state()))
	var wave_8_direction = $Icon/Wave.get_meta("last_8_direction", Vector2(0, -1))
	if get_direction() != 0:
		$Icon/Wave.scale.x = sign(get_direction())
	if not dash_control:
		if not is_on_floor() and not is_on_ceiling():
			if wave_8_direction == Vector2.UP or wave_8_direction == Vector2.DOWN:
				$Icon/Wave/Icon.rotation_degrees = lerpf($Icon/Wave/Icon.rotation_degrees, 90.0 * -wave_8_direction.y * sign(gravity_multiplier), 0.25 * delta * 60)
			elif wave_8_direction:
				if player_scale == PlayerScale.NORMAL:
					$Icon/Wave/Icon.rotation_degrees = lerpf($Icon/Wave/Icon.rotation_degrees, 45.0 * -wave_8_direction.y * sign(gravity_multiplier), 0.25 * delta * 60)
				elif player_scale == PlayerScale.MINI:
					$Icon/Wave/Icon.rotation_degrees = lerpf($Icon/Wave/Icon.rotation_degrees, 60.0 * -wave_8_direction.y * sign(gravity_multiplier), 0.25 * delta * 60)
				elif player_scale == PlayerScale.BIG:
					$Icon/Wave/Icon.rotation_degrees = lerpf($Icon/Wave/Icon.rotation_degrees, 30.0 * -wave_8_direction.y * sign(gravity_multiplier), 0.25 * delta * 60)
		else:
			$Icon/Wave/Icon.rotation = lerp_angle(
					$Icon/Wave/Icon.rotation,
					sprite_floor_angle * sign(gravity_multiplier) * $Icon/Wave.scale.x - gameplay_rotation,
					ICON_LERP_FACTOR * delta * 60)
	else:
		$Icon/Wave/Icon.rotation = lerpf($Icon/Wave/Icon.rotation, dash_control.angle * get_direction(), ICON_LERP_FACTOR * delta * 60)
	#endregion
	#region ufo
	$Icon/UFO.scale.y = sign(gravity_multiplier)
	$Icon/Jetpack.scale.y = sign(gravity_multiplier)
	if get_direction() != 0:
		$Icon/UFO.scale.x = sign(get_direction())
		$Icon/Jetpack.scale.x = sign(get_direction())
	if not dash_control:
		if not is_on_floor() and not is_on_ceiling() and speed_multiplier > 0.0:
			$Icon/UFO.rotation_degrees = lerpf($Icon/UFO.rotation_degrees, velocity.rotated(-gameplay_rotation).y * delta * get_direction() * 0.2, ICON_LERP_FACTOR * delta * 60)
		else:
			$Icon/UFO.rotation = lerp_angle($Icon/UFO.rotation, sprite_floor_angle, ICON_LERP_FACTOR * delta * 60)
		$Icon/Jetpack.rotation = lerp_angle(
				$Icon/Jetpack.rotation,
				deg_to_rad(velocity.rotated(-gameplay_rotation).x * delta * 5) + sprite_floor_angle,
				ICON_LERP_FACTOR * delta * 60)
	else:
		$Icon/UFO.rotation = lerpf($Icon/UFO.rotation, dash_control.angle * get_direction(), ICON_LERP_FACTOR * delta * 60)
		$Icon/Jetpack.rotation = lerpf($Icon/UFO.rotation, dash_control.angle * get_direction(), ICON_LERP_FACTOR * delta * 60)
	#endregion
	#region ball
	$Icon/Ball.scale.y = 1.0
	if speed_multiplier > 0.0:
		var rotation_delta := delta * 0.6 * gameplay_trigger_gravity_multiplier * (velocity.rotated(-gameplay_rotation).x / speed_multiplier)
		if not dash_control:
			rotation_delta *= gravity_multiplier
		$Icon/Ball.rotation_degrees += rotation_delta
	if not dash_control:
		var ball_grounded_look_factor = $Icon/Ball.get_meta("ball_grounded_look_factor", 0.0)
		if (abs(velocity.rotated(-gameplay_rotation).x) / speed_multiplier) < speed.x * 0.5:
			ball_grounded_look_factor = lerpf(ball_grounded_look_factor, 1.0, 10 * delta)
		else:
			ball_grounded_look_factor = lerpf(ball_grounded_look_factor, 0.0, 10 * delta)
		$Icon/Ball.set_meta("ball_grounded_look_factor", ball_grounded_look_factor)
		var ball_rotation_in_air: float = abs(sin(($Icon/Ball.rotation * TAU) / deg_to_rad(72*2)))
		$Icon/Ball.position = Vector2(0.0, lerpf(0.0, lerpf(0, 10, ball_rotation_in_air), ball_grounded_look_factor)).rotated(gameplay_rotation)
	#endregion
	#region spider/robot
	$Icon/Spider.rotation_degrees = gameplay_rotation_degrees
	$Icon/Spider/SpiderSprites.rotation = lerp_angle(
			$Icon/Spider/SpiderSprites.rotation,
			sprite_floor_angle * sign(gravity_multiplier),
			ICON_LERP_FACTOR * delta * 60)
	$Icon/Robot.rotation = lerp_angle(
			$Icon/Robot.rotation,
			sprite_floor_angle,
			ICON_LERP_FACTOR * delta * 60)
	if get_direction() != 0:
		$Icon/Spider/SpiderSprites.scale.x = sign(get_direction())
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
	%WaveTrail.width = lerpf(%WaveTrail.width, wave_trail_width, 0.25 * delta * 60)
	%WaveTrailInner.width = lerpf(%WaveTrailInner.width, wave_trail_width * 0.5, 0.25 * delta * 60)
	if displayed_gamemode == Gamemode.WAVE:
		%WaveTrail.modulate.a = 1.0
		%WaveTrailInner.modulate.a = 1.0
		%WaveTrail.length = lerpf(%WaveTrail.length, WAVE_TRAIL_LENGTH, delta * 60 * 0.2)
		%WaveTrailInner.length = lerpf(%WaveTrail.length, WAVE_TRAIL_LENGTH, delta * 60 * 0.2)
	else:
		%WaveTrail.length = 0
		%WaveTrailInner.length = 0
		%WaveTrail.modulate.a = move_toward(%WaveTrail.modulate.a, 0.0, delta * 60 * 0.2)
		%WaveTrailInner.modulate.a = move_toward(%WaveTrailInner.modulate.a, 0.0, delta * 60 * 0.2)
		if is_zero_approx(%WaveTrail.modulate.a):
			%WaveTrail.clear_points()
		if is_zero_approx(%WaveTrailInner.modulate.a):
			%WaveTrailInner.clear_points()


func _get_spider_velocity_delta() -> float:
	var _target_position = $Icon/Spider/SpiderCast.get_collision_point(0)
	var _spider_velocity_delta: float = abs((_target_position - position).rotated(-gameplay_rotation).y)
	_spider_velocity_delta -= LevelManager.CELL_SIZE/2.0 * scale.y
	var result := _spider_velocity_delta * gravity_multiplier * gameplay_trigger_gravity_multiplier
	_last_spider_trail = SPIDER_TRAIL.instantiate()
	_last_spider_trail_height = abs(result/SpiderTrail.SPIDER_TRAIL_HEIGHT)
	_last_spider_trail.scale.x = horizontal_direction
	_last_spider_trail.trail_rotation = gameplay_rotation
	return result


func _update_spider_state_machine() -> void:
	# `jump` was moved to _compute_velocity to only be triggered with orbs and pads
	# _spider_state_machine.travel("jump")
	if dash_control or (_get_jump_state() == -1 and not is_on_floor() and not is_on_ceiling() and not is_on_wall() and not $GroundCollider.shape is CircleShape2D):
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
	LevelManager.player_duals.clear()
	get_tree().reload_current_scene()


func _on_kill_collider_solid_body_entered(_body:Node2D) -> void:
	if _spider_jump_invulnerability_frames == 0:
		$DeathAnimator.play("DeathAnimation")


func _on_kill_collider_hazard_body_entered(_body:Node2D) -> void:
	if _spider_jump_invulnerability_frames == 0:
		$DeathAnimator.play("DeathAnimation")


func stop_dash() -> void:
	get_node("DashParticles").emitting = false
	get_node("DashFlame").hide()
	dash_control = null


func _on_solid_overlap_check_body_exited(body:Node2D) -> void:
	body = body as CollisionObject2D
	body.collision_layer = 1 << 1
	body.get_node("Hitbox").debug_color = Color("#0012b340") # DEBUG: Hardcoded name for hitbox color

