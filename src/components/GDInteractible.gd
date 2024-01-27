@tool extends Area2D

class_name GDInteractible

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
@export var _other_portal_type: OtherPortal

# @@show_if(object_type == ObjectType.OTHER_PORTAL and _other_portal_type == GRAVITY_PORTAL)
@export var _gravity_portal_type: GravityPortal
# @@show_if(object_type == ObjectType.OTHER_PORTAL and _other_portal_type == SIZE_PORTAL)
@export var _mini: bool

# @@show_if(object_type == ObjectType.ORB or object_type == ObjectType.PAD)
@export var _reverse: bool
# @@show_if(object_type == ObjectType.GAMEMODE_PORTAL)
@export var _freefly: bool = true

#endregion

var _player: Player

func _ready() -> void:
	_player = LevelManager.player
	connect("body_entered", Callable(self, "_on_player_enter"))
	connect("body_exited", Callable(self, "_on_player_exit"))

func _process(_delta: float) -> void:
	if object_type == ObjectType.GAMEMODE_PORTAL or (object_type == ObjectType.OTHER_PORTAL and _other_portal_type == OtherPortal.GRAVITY_PORTAL):
		if not Engine.is_editor_hint() and LevelManager.player_camera != null and _other_portal_type != OtherPortal.GRAVITY_PORTAL:
			$IndicatorIcon.global_rotation = LevelManager.player_camera.rotation
		else:
			$IndicatorIcon.global_rotation = 0.0
		$IndicatorIcon.global_scale.x = abs(scale.x)
		$IndicatorIcon.global_scale.y = abs(scale.y)

func _on_player_enter(_body: Node2D) -> void:
	if object_type == ObjectType.ORB:
		_player.orb_collisions |= _orb_type
		if _orb_type == Orb.SPIDER:
			_player._set_spider_shapecast_rotation(rotation)
	elif object_type == ObjectType.PAD:
		_player.pad_collisions |= _pad_type
	elif object_type == ObjectType.GAMEMODE_PORTAL:
		LevelManager.player.gamemode = _gamemode_portal_type
	elif object_type == ObjectType.OTHER_PORTAL:
		if _other_portal_type == OtherPortal.SIZE_PORTAL:
			_player._mini = _mini


func _on_player_exit(_body: Node2D) -> void:
	if object_type == ObjectType.ORB:
		_player.orb_collisions &= ~_orb_type
		if _orb_type == Orb.SPIDER:
			_player._set_spider_shapecast_rotation(0.0)
	elif object_type == ObjectType.PAD:
		_player.pad_collisions &= ~_pad_type