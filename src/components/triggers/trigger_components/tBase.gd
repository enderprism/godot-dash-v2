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
		_set_hitbox_shape()
		notify_property_list_changed()

@export var hitbox_height: float = 64.0:
	set(value):
		hitbox_height = value
		_set_hitbox_shape()

## The trigger's target.
@export var _target: Node:
	set(value):
		_target = value
		emit_signal("target_changed")

@export var target_group: StringName

## If the trigger can be used multiple times.
@export var multi_usage: bool = false

func _validate_property(property: Dictionary) -> void:
	if property.name == "hitbox_height" and _hitbox_shape != TriggerHitboxShape.LINE:
		property.usage = PROPERTY_USAGE_NO_EDITOR

## The trigger's sprite. Hidden at runtime unless collision shapes are visible ([code]Debug → Visible Collision Shapes[/codeb]).
var sprite: Sprite2D
## The trigger's collision shape.
var _hitbox: CollisionShape2D

func _set_hitbox_shape() -> void:
	if _hitbox != null:
		match _hitbox_shape:
			TriggerHitboxShape.LINE:
				_hitbox.shape = SegmentShape2D.new()
				_hitbox.shape.a = Vector2(0, -hitbox_height * LevelManager.CELL_SIZE)
				_hitbox.shape.b = Vector2(0,  hitbox_height * LevelManager.CELL_SIZE)
			TriggerHitboxShape.SQUARE:
				_hitbox.shape = RectangleShape2D.new()
				_hitbox.shape.size = Vector2.ONE * LevelManager.CELL_SIZE
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
		_set_hitbox_shape()
		add_child(_hitbox)
		_hitbox.set_owner(self)
	else:
		_hitbox = $Hitbox
	if not has_node("Sprite"):
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		add_child(sprite)
		sprite.set_owner(self)
		sprite.scale = Vector2.ONE/4
	else:
		sprite = $Sprite
	sprite.set_texture(DEFAULT_TRIGGER_TEXTURE)
	if not multi_usage and not body_entered.is_connected(_disable): body_entered.connect(_disable)

func _physics_process(_delta: float) -> void:
	sprite.visible = _sprite_visible()
	if not get_parent() is tGameplayRotate:
		sprite.global_rotation = 0.0
	sprite.global_scale = Vector2.ONE/4

func _disable(_body: Node2D) -> void:
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	set_deferred("process_mode", PROCESS_MODE_DISABLED)

func _sprite_visible() -> bool:
	return Engine.is_editor_hint() or (not Engine.is_editor_hint() and get_tree().is_debugging_collisions_hint())