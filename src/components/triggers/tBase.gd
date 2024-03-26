@tool
class_name tBase
extends Area2D
## The base class for Godot Dash triggers.

signal target_changed

const DEFAULT_TRIGGER_TEXTURE: Texture2D = preload("res://assets/textures/Circle.svg")

enum TriggerHitboxShape {
	LINE,
	SQUARE,
	DISABLED
}

@export var _hitbox_shape: TriggerHitboxShape = TriggerHitboxShape.LINE:
	set(value):
		_hitbox_shape = value
		_set_hitbox_shape(value)

## The trigger's target.
@export var _target: Node:
	set(value):
		_target = value
		emit_signal("target_changed")

## The trigger's sprite. Hidden at runtime unless collision shapes are visible ([code]Debug → Visible Collision Shapes[/codeb]).
var _sprite: Sprite2D
## The trigger's collision shape.
var _hitbox: CollisionShape2D

func _set_hitbox_shape(hitbox_shape: TriggerHitboxShape) -> void:
	if _hitbox != null:
		match hitbox_shape:
			TriggerHitboxShape.LINE:
				_hitbox.shape = SegmentShape2D.new()
				_hitbox.shape.a = Vector2(0, -8192.0)
				_hitbox.shape.b = Vector2(0,  8192.0)
			TriggerHitboxShape.SQUARE:
				_hitbox.shape = RectangleShape2D.new()
				_hitbox.shape.size = Vector2.ONE * 128.0
			TriggerHitboxShape.DISABLED:
				_hitbox.shape = RectangleShape2D.new()
				_hitbox.shape.size = Vector2.ZERO

func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	if not has_node("Hitbox"):
		_hitbox = CollisionShape2D.new()
		_hitbox.name = "Hitbox"
		_hitbox.debug_color = Color("fff5006b")
		_set_hitbox_shape(_hitbox_shape)
		add_child(_hitbox)
		_hitbox.set_owner(self)
	else:
		_hitbox = $Hitbox
	if not has_node("Sprite"):
		_sprite = Sprite2D.new()
		_sprite.name = "Sprite"
		add_child(_sprite)
		_sprite.set_owner(self)
		_sprite.scale = Vector2.ONE/4
	else:
		_sprite = $Sprite
	_sprite.set_texture(DEFAULT_TRIGGER_TEXTURE)

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not get_tree().is_debugging_collisions_hint():
		_sprite.hide()
	_sprite.global_rotation = 0.0
