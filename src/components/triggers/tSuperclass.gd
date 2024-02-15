@tool
extends Area2D
## The base class for Godot Dash triggers.

## If true, changes the trigger's [member _hitbox] from a square [RectangleShape2D] to a  vertical [SegmentShape2D].
@export var _touch_trigger: bool:
	set(value):
		_touch_trigger = value
		_set_hitbox_shape(value)

## The trigger's sprite. Hidden at runtime unless collision shapes are visible ([code]Debug → Visible Collision Shapes[/codeb]).
var _sprite: Sprite2D
## The trigger's collision shape.
var _hitbox: CollisionShape2D
## The trigger's texture, displayed by [member _sprite]. Should be overriden in [code]_init()[/code] when used in a child class.
var _texture: Resource = preload("res://assets/textures/Circle.svg")

func _set_hitbox_shape(touch_trigger: bool) -> void:
	if touch_trigger:
		_hitbox.shape = RectangleShape2D.new()
		_hitbox.shape.size = Vector2.ONE * 128.0
	else:
		_hitbox.shape = SegmentShape2D.new()
		_hitbox.shape.a = Vector2(0, -8192.0)
		_hitbox.shape.b = Vector2(0,  8192.0)

func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	_hitbox = CollisionShape2D.new()
	_hitbox.debug_color = Color("fff5006b")
	_set_hitbox_shape(_touch_trigger)
	add_child(_hitbox)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_sprite.scale = Vector2.ONE/4
	_sprite.set_texture(_texture)
	body_entered.connect(_run)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not get_tree().is_debugging_collisions_hint():
		_sprite.hide()
	_sprite.global_rotation = 0.0

func _run(_body: Node2D) -> void:
	pass