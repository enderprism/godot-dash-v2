@tool
class_name TriggerBase
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
@export var single_usage: bool = true

func _validate_property(property: Dictionary) -> void:
	if property.name == "hitbox_height" and _hitbox_shape != TriggerHitboxShape.LINE:
		property.usage = PROPERTY_USAGE_NO_EDITOR

## The trigger's sprite. Hidden at runtime unless collision shapes are visible ([code]Debug → Visible Collision Shapes[/codeb]).
var sprite: Sprite2D
## The trigger's collision shape.
var _hitbox: CollisionShape2D
var _single_usage_component: SingleUsageComponent
var _hitbox_display: TriggerHitboxDisplay

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
	_hitbox = get_node_or_null("Hitbox") as CollisionShape2D
	if _hitbox == null:
		_hitbox = CollisionShape2D.new()
		_hitbox.name = "Hitbox"
		_hitbox.debug_color = Color("fff5006b")
		_set_hitbox_shape()
		add_child(_hitbox)
		_hitbox.set_owner(self)
	sprite = get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		add_child(sprite)
		sprite.set_owner(self)
		sprite.scale = Vector2.ONE * 0.2
	sprite.set_texture(DEFAULT_TRIGGER_TEXTURE)
	_single_usage_component = get_node_or_null("SingleUsageComponent") as SingleUsageComponent
	if _single_usage_component == null:
		_single_usage_component = SingleUsageComponent.new()
		_single_usage_component.name = "SingleUsageComponent"
		add_child(_single_usage_component)
		_single_usage_component.set_owner(self)
	_hitbox_display = get_node_or_null("TriggerHitboxDisplay") as TriggerHitboxDisplay
	if _hitbox_display == null:
		_hitbox_display = TriggerHitboxDisplay.new()
		_hitbox_display.name = "SingleUsageComponent"
		add_child(_hitbox_display)
		_hitbox_display.set_owner(self)
	if LevelManager.in_editor:
		var editor_selection_collider := LevelManager.editor_selection_collider.instantiate()
		add_child(editor_selection_collider)

func _physics_process(_delta: float) -> void:
	sprite.visible = sprite_visible()
	if not get_parent() is GameplayRotateTrigger:
		sprite.global_rotation = 0.0
	sprite.global_scale = Vector2.ONE * 0.2

func sprite_visible() -> bool:
	return Engine.is_editor_hint() or (not Engine.is_editor_hint() and get_tree().is_debugging_collisions_hint())