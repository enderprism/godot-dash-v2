@tool
class_name TriggerBase
extends Interactable
## The base class for Godot Dash triggers.

signal target_changed
signal hitbox_shape_changed(hitbox_shape: TriggerHitboxShape, hitbox_position: Vector2, hitbox_height: float)

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


func _validate_property(property: Dictionary) -> void:
	if property.name == "hitbox_height" and _hitbox_shape != TriggerHitboxShape.LINE:
		property.usage = PROPERTY_USAGE_NO_EDITOR

## The trigger's sprite. Hidden at runtime unless collision shapes are visible ([code]Debug → Visible Collision Shapes[/codeb]).
var sprite: Sprite2D
## The trigger's UI. [TriggerEditor] will instantiate it.
var ui_path: String
## The trigger's collision shape.
var _hitbox: CollisionShape2D
var _hitbox_display: TriggerHitboxDisplay

func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	_hitbox_display = NodeUtils.get_node_or_add(self, "TriggerHitboxDisplay", load("res://src/triggers/trigger_components/TriggerHitboxDisplay.gd"), NodeUtils.INTERNAL)
	_hitbox = NodeUtils.get_node_or_add(self, "Hitbox", CollisionShape2D, NodeUtils.INTERNAL)
	sprite = NodeUtils.get_node_or_add(self, "Sprite", Sprite2D, NodeUtils.INTERNAL)
	_hitbox.debug_color = Color("fff5006b")
	sprite.scale = Vector2.ONE * 0.2
	sprite.set_texture(DEFAULT_TRIGGER_TEXTURE)
	NodeUtils.get_node_or_add(self, "SingleUsageComponent", SingleUsageComponent, NodeUtils.INTERNAL)
	NodeUtils.connect_new(hitbox_shape_changed, _hitbox_display.update_shape)
	_set_hitbox_shape()

func _physics_process(_delta: float) -> void:
	sprite.visible = sprite_visible()
	if not get_parent() is GameplayRotateTrigger:
		if Engine.is_editor_hint() or LevelManager.player_camera == null:
			sprite.global_rotation = 0.0
		else:
			sprite.global_rotation = LevelManager.player_camera.global_rotation
	sprite.global_scale = Vector2.ONE * 0.2

func sprite_visible() -> bool:
	return Engine.is_editor_hint() or (not Engine.is_editor_hint() and get_tree().is_debugging_collisions_hint()) or LevelManager.in_editor


func _set_hitbox_shape() -> void:
	if _hitbox != null:
		hitbox_shape_changed.emit(_hitbox_shape, _hitbox.position, hitbox_height)
		match _hitbox_shape:
			TriggerHitboxShape.LINE:
				_hitbox.shape = SegmentShape2D.new()
				_hitbox.shape.a = Vector2(0, -hitbox_height * LevelManager.CELL_SIZE)
				_hitbox.shape.b = Vector2(0,  hitbox_height * LevelManager.CELL_SIZE)
			TriggerHitboxShape.SQUARE:
				_hitbox.shape = RectangleShape2D.new()
				_hitbox.shape.size = Vector2.ONE * LevelManager.CELL_SIZE
			TriggerHitboxShape.DISABLED:
				_hitbox.shape = null
