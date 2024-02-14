@tool extends Area2D

class_name GDInteractible

const CIRCLE_EFFECT_GROW_DURATION: float = 0.25
const CIRCLE_EFFECT_GROW_SIZE: Vector2 = Vector2(2.0/4, 2.0/4)
const REBOUND_VELOCITY_SETTER_THRESHOLD: float = 20.0

#region enums
enum Orb {
	YELLOW = 1,
	PINK = 2,
	RED = 4,
	BLUE = 8,
	GREEN = 16,
	BLACK = 32,
	SPIDER = 64,
	DASH_GREEN = 128,
	DASH_MAGENTA = 256,
	REBOUND = 512,
	TELEPORT = 1024,
	TOGGLE = 2048,
}

enum Pad {
	YELLOW = 1,
	PINK = 2,
	RED = 4,
	BLUE = 8,
	SPIDER = 16,
	REBOUND = 32,
}

enum SpeedPortal {
	SPEED_1X,
	SPEED_2X,
	SPEED_3X,
	SPEED_4X,
	SPEED_05X,
	SPEED_0X,
	SPEED_5X,
}

enum OtherPortal {
	GRAVITY_PORTAL,
	SIZE_PORTAL,
	TELEPORTAL,
	MIRROR_PORTAL,
	DUAL_PORTAL,
}

enum ObjectType {
	ORB,
	PAD,
	GAMEMODE_PORTAL,
	SPEED_PORTAL,
	OTHER_PORTAL,
}

enum GravityPortal {
	NORMAL,
	FLIPPED,
	TOGGLE,
}

enum HorizontalDirection {
	USE_CURRENT,
	SET,
	FLIP,
}

enum ToggleState {
	ON,
	OFF,
	FLIP,
}
#endregion

#region exports
@export var object_type: ObjectType

# @@show_if(object_type == ObjectType.ORB)
@export var _orb_type: Orb

# @@show_if(object_type == ObjectType.PAD)
@export var _pad_type: Pad

# @@show_if(object_type == ObjectType.GAMEMODE_PORTAL)
@export var _gamemode_portal_type: Player.Gamemode

# @@show_if(object_type == ObjectType.SPEED_PORTAL)
@export var _speed_portal_type: SpeedPortal

# @@show_if(object_type == ObjectType.OTHER_PORTAL)
@export var _other_portal_type: OtherPortal = OtherPortal.GRAVITY_PORTAL

# @@show_if(object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.GRAVITY_PORTAL)
@export var _gravity_portal_type: GravityPortal = GravityPortal.NORMAL

# @@show_if(object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.SIZE_PORTAL)
@export var _mini: bool

# @@show_if(object_type == ObjectType.ORB or object_type == ObjectType.PAD)
@export var _horizontal_direction: HorizontalDirection

# @@show_if(object_type == ObjectType.ORB and _horizontal_direction == HorizontalDirection.SET or object_type == ObjectType.PAD and _horizontal_direction == HorizontalDirection.SET)
@export var _reverse: bool

# @@show_if(object_type == ObjectType.GAMEMODE_PORTAL)
@export var _freefly: bool

# @@show_if(object_type == ObjectType.ORB and _orb_type == Orb.TOGGLE)
@export var _toggled_groups: Array[GDToggledGroup]

# @@show_if(_other_portal_type == OtherPortal.TELEPORTAL and object_type == ObjectType.OTHER_PORTAL or object_type == ObjectType.ORB and _orb_type == Orb.TELEPORT)
@export var _teleport_target: Node2D

# @@show_if(_other_portal_type == OtherPortal.TELEPORTAL and object_type == ObjectType.OTHER_PORTAL or object_type == ObjectType.ORB and _orb_type == Orb.TELEPORT)
@export var _ignore_x: bool

# @@show_if(_other_portal_type == OtherPortal.TELEPORTAL and object_type == ObjectType.OTHER_PORTAL or object_type == ObjectType.ORB and _orb_type == Orb.TELEPORT)
@export var _ignore_y: bool

# @@show_if(_other_portal_type == OtherPortal.TELEPORTAL and object_type == ObjectType.OTHER_PORTAL or object_type == ObjectType.ORB and _orb_type == Orb.TELEPORT)
@export var _override_player_velocity: bool

# @@show_if(_override_player_velocity and object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.TELEPORTAL or object_type == ObjectType.ORB and _orb_type == Orb.TELEPORT)
@export var _new_player_velocity: Vector2

# @@show_if(object_type == ObjectType.ORB and _orb_type == Orb.REBOUND or object_type == ObjectType.PAD and _pad_type == Pad.REBOUND)
@export var _rebound_gradient: Gradient

# @@show_if(object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.MIRROR_PORTAL)
@export var _mirror_screen: bool

# @@show_if(object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.DUAL_PORTAL)
@export var _dual: bool

@export var _multi_usage: bool = true
#endregion

var _player: Player
var _rebound_factor: float
var _pulse_white_color: Color = Color.WHITE


func _ready() -> void:
	_pulse_white_color.a = 0
	_player = LevelManager.player
	connect("body_entered", Callable(self, "_on_player_enter"))
	connect("body_exited", Callable(self, "_on_player_exit"))
	if object_type == ObjectType.ORB:
		_player.orb_clicked.connect(_pulse_shrink)
		if _multi_usage:
			_player.orb_clicked.connect(_set_player_orb_collisions)
		if _orb_type == Orb.TELEPORT:
			_player.teleported.connect(_teleport_player)
		elif _orb_type == Orb.TOGGLE:
			_player.orb_clicked.connect(_toggle.bind(_toggled_groups))

func _process(delta: float) -> void:

	if has_node("Fill"):
		$Fill.modulate = self_modulate

	if not Engine.is_editor_hint():
		if object_type == ObjectType.ORB and _orb_type == Orb.REBOUND or object_type == ObjectType.PAD and _pad_type == Pad.REBOUND:
			_rebound()
			$ReboundCancelArea/Hitbox.debug_color = Color("397f0033")
		if object_type == ObjectType.ORB:
			if _player._orb_collisions_last_setters.has(_orb_type) and _player._orb_collisions_last_setters[_orb_type] == self \
					and _player._click_buffer_state == Player.ClickBufferState.JUMPING and has_overlapping_bodies():
				_player._click_buffer_state = Player.ClickBufferState.BUFFERING
			if _orb_type == Orb.BLUE:
				$Sprite.scale.y = sign(_player._gravity_multiplier)/4
				$Sprite.global_rotation = _player._gameplay_rotation
			elif _orb_type == Orb.BLACK or _orb_type == Orb.GREEN:
				$Sprite.global_rotation += 5 * delta
		if object_type == ObjectType.ORB and _orb_type == Orb.TELEPORT \
				or object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.TELEPORTAL:
			$TargetLink.hide()
		if object_type != ObjectType.ORB and object_type != ObjectType.PAD:
			_pulse_white_tick()
		if object_type == ObjectType.ORB and _orb_type == Orb.SPIDER and scale.y < 0:
			scale.y *= -1
			rotation_degrees *= -1
		if has_node("DashOrbPreview"):
			$DashOrbPreview.hide()
		$Hitbox.debug_color = Color("00ff0033")
	else:
		if object_type == ObjectType.ORB and _orb_type == Orb.BLUE:
			$Sprite.global_rotation = 0.0
		if object_type == ObjectType.ORB and _orb_type == Orb.REBOUND or object_type == ObjectType.PAD and _pad_type == Pad.REBOUND:
			$ReboundCancelArea/Hitbox.debug_color = Color("397f0000")
		if object_type == ObjectType.ORB and _orb_type == Orb.TELEPORT \
				or object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.TELEPORTAL:
			# I KNOW THIS IS UGLY BUT IF I DON'T ENCASE IT IN 3 SEPARATE CHECKS THE DEBUGGER GOES CRAZY D:
			if _teleport_target != null:
				if $TargetLink.get_point_position(1) != _teleport_target.global_position:
					$TargetLink.clear_points()
					$TargetLink.add_point(Vector2.ZERO, 0)
					$TargetLink.add_point(to_local(_teleport_target.global_position), 1)
			elif $TargetLink.get_point_count() != 0:
				$TargetLink.clear_points()
		$Hitbox.debug_color = Color("00ff0000")


	if object_type == ObjectType.ORB and (_orb_type == Orb.TELEPORT or _orb_type == Orb.TOGGLE):
		if has_node("ParticleEmitter"):
			$ParticleEmitter.modulate = self_modulate
		if has_node("PulseShrink"):
			$PulseShrink.modulate = self_modulate

	if has_node("Sprites/IndicatorIcon") \
		and object_type == ObjectType.GAMEMODE_PORTAL \
		or (object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.GRAVITY_PORTAL):
		if not Engine.is_editor_hint() and LevelManager.player_camera != null and _other_portal_type != OtherPortal.GRAVITY_PORTAL:
			$Sprites/IndicatorIcon.global_rotation = LevelManager.player_camera.rotation
		else:
			$Sprites/IndicatorIcon.global_rotation = 0.0
		$Sprites/IndicatorIcon.global_scale.x = abs(scale.x)
		$Sprites/IndicatorIcon.global_scale.y = abs(scale.y)

func _on_player_enter(_body: Node2D) -> void:
	_pulse_grow()
	if object_type == ObjectType.ORB:
		_player._orb_collisions_last_setters[_orb_type] = self
		_player._orb_collisions |= _orb_type
		_set_reverse(_reverse)
		if _orb_type == Orb.SPIDER:
			var _player_gravity_to_rotation: float = 0.0 if _player._gravity_multiplier > 0 else 180.0
			if is_equal_approx(fmod((abs(rotation_degrees) - _player_gravity_to_rotation)/180, 2), 1):
				_player.get_node("Icon/Spider/SpiderCast").scale.y = -1
			else:
				_player.get_node("Icon/Spider/SpiderCast").scale.y = 1
		elif _orb_type == Orb.DASH_GREEN or _orb_type == Orb.DASH_MAGENTA:
			_player._dash_orb_rotation = global_rotation
			_player._dash_orb_position = global_position
	elif object_type == ObjectType.PAD:
		set_deferred("monitoring", _multi_usage)
		_set_reverse(_reverse)
		_player._pad_collisions |= _pad_type
	elif object_type == ObjectType.GAMEMODE_PORTAL:
		set_deferred("monitoring", _multi_usage)
		_pulse_shrink()
		_pulse_white_start()
		LevelManager.player.gamemode = _gamemode_portal_type
		_player._mini = _player._mini
	elif object_type == ObjectType.SPEED_PORTAL:
		set_deferred("monitoring", _multi_usage)
		_pulse_white_start()
		match _speed_portal_type:
			SpeedPortal.SPEED_1X:
				_player._speed_multiplier = 1.0
			SpeedPortal.SPEED_2X:
				_player._speed_multiplier = 1.243
			SpeedPortal.SPEED_3X:
				_player._speed_multiplier = 1.502
			SpeedPortal.SPEED_4X:
				_player._speed_multiplier = 1.849
			SpeedPortal.SPEED_5X:
				_player._speed_multiplier = 1.0
			SpeedPortal.SPEED_0X:
				_player._speed_multiplier = 0.0
			SpeedPortal.SPEED_05X:
				_player._speed_multiplier = 0.807
	elif object_type == ObjectType.OTHER_PORTAL:
		set_deferred("monitoring", _multi_usage)
		_pulse_shrink()
		_pulse_white_start()
		match _other_portal_type:
			OtherPortal.SIZE_PORTAL:
				_player._mini = _mini
			OtherPortal.GRAVITY_PORTAL:
				match _gravity_portal_type:
					GravityPortal.NORMAL:
						_player._gravity_multiplier = abs(_player._gravity_multiplier)
					GravityPortal.FLIPPED:
						_player._gravity_multiplier = abs(_player._gravity_multiplier) * -1
					GravityPortal.TOGGLE:
						_player._gravity_multiplier *= -1
			OtherPortal.TELEPORTAL:
				_set_reverse(_reverse)
				_teleport_player()

func _rebound() -> void:
	if _player.position.rotated(-_player._gameplay_rotation).y < $ReboundObjectScaleOrigin.global_position.rotated(-_player._gameplay_rotation).y \
			and _player.velocity.rotated(-_player._gameplay_rotation).y <= 0:
		var _player_rebound_offset: float = $ReboundObjectScaleOrigin.global_position.rotated(-_player._gameplay_rotation).y - _player.position.rotated(-_player._gameplay_rotation).y
		_rebound_factor = _player_rebound_offset/(Player.TERMINAL_VELOCITY.y*0.25)
	var _rebound_color: Color = _rebound_gradient.sample(clampf(_rebound_factor, 0.0, 1.0))
	$ParticleEmitter.modulate = _rebound_color
	$PulseGrow.modulate.r = _rebound_color.r
	$PulseGrow.modulate.g = _rebound_color.g
	$PulseGrow.modulate.b = _rebound_color.b
	$ReboundObjectScaleOrigin/Fill.modulate = _rebound_color
	if object_type == ObjectType.PAD:
		$ReboundObjectScaleOrigin.scale.y = lerpf(0.7, 1.7, _rebound_factor)
		$Hitbox.scale.y = lerpf(0.7, 1.7, _rebound_factor)
	elif object_type == ObjectType.ORB:
		$ReboundObjectScaleOrigin.scale.x = lerpf(0.7, 1.7, _rebound_factor)
		$ReboundObjectScaleOrigin.scale.y = lerpf(0.7, 1.7, _rebound_factor)
		$Hitbox.scale.x = lerpf(0.7, 1.7, _rebound_factor)
		$Hitbox.scale.y = lerpf(0.7, 1.7, _rebound_factor)
	if _player.velocity.rotated(-_player._gameplay_rotation).y * sign(_player._gravity_multiplier) > 0:
		_player._rebound_velocity = _player.velocity.rotated(-_player._gameplay_rotation).y
	elif _player.velocity.rotated(-_player._gameplay_rotation).y == 0 and _player._get_jump_state() == -1 and _player.is_on_floor() and $ReboundCancelArea.has_overlapping_bodies():
		_player._rebound_velocity = 0.0

func _on_player_exit(_body: Node2D) -> void:
	_player._teleport_position_buffer = Vector2.ZERO
	_player._teleport_velocity_buffer = Vector2.ZERO
	_player._teleport_override_velocity = false
	_player._reverse_direction_buffer = 0
	if object_type == ObjectType.ORB:
		if _player._orb_collisions_last_setters[_orb_type] == self:
			_player._orb_collisions &= ~_orb_type
		if _orb_type == Orb.SPIDER:
			_player.get_node("Icon/Spider/SpiderCast").scale.y = 1

func _pulse_grow() -> void:
	if has_node("PulseGrow"):
		create_tween().tween_property(
			$PulseGrow,
			"scale",
			CIRCLE_EFFECT_GROW_SIZE,
			CIRCLE_EFFECT_GROW_DURATION,) \
			.from(Vector2.ZERO) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_QUART)
		create_tween().tween_property(
			$PulseGrow,
			"modulate:a",
			0.0,
			CIRCLE_EFFECT_GROW_DURATION,) \
			.from(1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_SINE)

func _pulse_white_start() -> void:
	if object_type != ObjectType.ORB and object_type != ObjectType.PAD:
		create_tween().tween_property(
			self,
			"_pulse_white_color:a",
			0.0,
			CIRCLE_EFFECT_GROW_DURATION,) \
			.from(0.5) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_SINE)

func _pulse_white_tick() -> void:
	if has_node("Sprites"): # For multiple-sprite GDInteractibles (Gamemode Portals, etc.)
		$Sprites.material.set_shader_parameter("shine_color", _pulse_white_color)
	if has_node("Sprite"): # For single-sprite GDInteractibles (Speed Portals)
		$Sprite.material.set_shader_parameter("shine_color", _pulse_white_color)

func _pulse_shrink() -> void:
	if has_node("PulseShrink") and (object_type == ObjectType.GAMEMODE_PORTAL or object_type == ObjectType.OTHER_PORTAL or (object_type == ObjectType.ORB and has_overlapping_bodies())):
		create_tween().tween_property(
			$PulseShrink,
			"scale",
			Vector2.ZERO,
			CIRCLE_EFFECT_GROW_DURATION * 2,) \
			.from(CIRCLE_EFFECT_GROW_SIZE) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_QUAD)
		create_tween().tween_property(
			$PulseShrink,
			"modulate:a",
			0.0,
			CIRCLE_EFFECT_GROW_DURATION * 2,) \
			.from(1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_SINE)

func _set_player_orb_collisions() -> void:
	if has_overlapping_bodies():
		_player._click_buffer_state = Player.ClickBufferState.JUMPING
		_player._orb_collisions |= _orb_type
		_player._orb_collisions_last_setters[_orb_type] = self

func _set_reverse(reverse: bool) -> void:
	if _horizontal_direction == HorizontalDirection.SET:
		_player._reverse_direction_buffer = -1 if reverse else 1
	elif _horizontal_direction == HorizontalDirection.FLIP:
		_player._reverse_direction_buffer = _player._horizontal_direction * -1

func _teleport_player() -> void:
	if _teleport_target != null and has_overlapping_bodies():
		if not _ignore_x:
			_player.position.x = _teleport_target.global_position.x
		if not _ignore_y:
			_player.position.y = _teleport_target.global_position.y
		if _override_player_velocity:
			_player.velocity = _new_player_velocity.rotated(_player._gameplay_rotation)

func _toggle(toggled_groups):
	if has_overlapping_bodies():
		for toggled_group in toggled_groups:
			var group = get_node(toggled_group._group)
			var state = toggled_group._state
			if state == ToggleState.FLIP:
				if group.process_mode == PROCESS_MODE_INHERIT: # If it is toggled on
					state = ToggleState.OFF
				elif group.process_mode == PROCESS_MODE_DISABLED: # If it is toggled off
					state = ToggleState.ON
			match state:
				ToggleState.ON:
					group.set_deferred("process_mode", PROCESS_MODE_INHERIT)
					group.show()
				ToggleState.OFF:
					group.set_deferred("process_mode", PROCESS_MODE_DISABLED)
					group.hide()
