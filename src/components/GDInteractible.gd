@tool extends Area2D

class_name GDInteractible

const CIRCLE_EFFECT_GROW_DURATION: float = 0.25
const CIRCLE_EFFECT_GROW_SIZE: Vector2 = Vector2(2.0, 2.0)

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

# @@show_if(object_type == ObjectType.ORB or object_type == ObjectType.PAD and _horizontal_direction == HorizontalDirection.SET)
@export var _reverse: bool

# @@show_if(object_type == ObjectType.GAMEMODE_PORTAL)
@export var _freefly: bool = true

# @@show_if(object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.TELEPORTAL)
@export var _teleport_target: Node2D

# @@show_if(object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.TELEPORTAL)
@export var _override_player_velocity: bool = false

# @@show_if(object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.TELEPORTAL and _override_player_velocity)
@export var _new_player_velocity: Vector2

#endregion

var _player: Player

func _ready() -> void:
	_player = LevelManager.player
	connect("body_entered", Callable(self, "_on_player_enter"))
	connect("body_exited", Callable(self, "_on_player_exit"))

func _process(_delta: float) -> void:
	if has_node("ParticleEmitter"):
		$ParticleEmitter.process_material.gravity = Vector3(
			Vector2(
				0.0,
				-128.0,
			).rotated(rotation).x,
			Vector2(
				0.0,
				-128.0,
			).rotated(rotation).y,
			0.0
		)
	if has_node("./IndicatorIcon") \
		and object_type == ObjectType.GAMEMODE_PORTAL \
		or (object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.GRAVITY_PORTAL):
		if not Engine.is_editor_hint() and LevelManager.player_camera != null and _other_portal_type != OtherPortal.GRAVITY_PORTAL:
			$IndicatorIcon.global_rotation = LevelManager.player_camera.rotation
		else:
			$IndicatorIcon.global_rotation = 0.0
		$IndicatorIcon.global_scale.x = abs(scale.x)
		$IndicatorIcon.global_scale.y = abs(scale.y)

func _on_player_enter(_body: Node2D) -> void:
	if (object_type == ObjectType.ORB and _orb_type == Orb.TELEPORT) \
		or (object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.TELEPORTAL):
		_teleport_player(_teleport_target, _override_player_velocity, _new_player_velocity)
	if object_type == ObjectType.ORB:
		_circle_effect()
		_player._orb_collisions |= _orb_type
		if _horizontal_direction == HorizontalDirection.SET:
			_player._reverse = _reverse
		elif _horizontal_direction == HorizontalDirection.FLIP:
			_player._reverse =  not _player._reverse
		if _orb_type == Orb.SPIDER:
			_player._set_spider_shapecast_rotation(rotation)
	elif object_type == ObjectType.PAD:
		_circle_effect()
		if _horizontal_direction == HorizontalDirection.SET:
			_player._reverse = _reverse
		elif _horizontal_direction == HorizontalDirection.FLIP:
			_player._reverse =  not _player._reverse
		_player._pad_collisions |= _pad_type
	elif object_type == ObjectType.GAMEMODE_PORTAL:
		LevelManager.player.gamemode = _gamemode_portal_type
		_player._mini = _player._mini
	elif object_type == ObjectType.OTHER_PORTAL:
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

func _circle_effect() -> void:
	if has_node("Circle"):
		# $Circle.position = 
		create_tween().tween_property(
			$Circle,
			"scale",
			CIRCLE_EFFECT_GROW_SIZE,
			CIRCLE_EFFECT_GROW_DURATION,) \
			.from(Vector2.ZERO) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_QUART)
		create_tween().tween_property(
			$Circle,
			"modulate:a",
			0.0,
			CIRCLE_EFFECT_GROW_DURATION,) \
			.from(1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_QUART)

func _on_player_exit(_body: Node2D) -> void:
	if object_type == ObjectType.ORB:
		_player.orb_collisions &= ~_orb_type
		if _orb_type == Orb.SPIDER:
			_player._set_spider_shapecast_rotation(0.0)
	elif object_type == ObjectType.PAD:
		_player._pad_collisions &= ~_pad_type

func _teleport_player(_target: Node2D, _override_velocity: bool, _new_velocity: Vector2) -> void:
	_player.position = _target.position
	if _override_velocity:
		_player.velocity = _new_velocity.rotated(_player._gameplay_rotation)