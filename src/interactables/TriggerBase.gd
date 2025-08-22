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

@export var target_group: StringName:
	set(value):
		target_group = value
		if group_display == null:
			_center_anchor = NodeUtils.get_node_or_add(self, "Center Anchor", Control, NodeUtils.INTERNAL)
			group_display = NodeUtils.get_node_or_add(_center_anchor, "Group Display", Label, NodeUtils.INTERNAL)
		group_display.label_settings = preload("res://resources/TriggerGroupDisplay.tres")
		group_display.text = target_group.trim_prefix(GroupEditor.GROUP_PREFIX)
		group_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		group_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		move_child(group_display, -1)
		var update_width := func(): group_display.position.x = -group_display.size.x/2
		group_display.position.y = 6.0
		update_width.call_deferred()


func _validate_property(property: Dictionary) -> void:
	if property.name == "hitbox_height" and _hitbox_shape != TriggerHitboxShape.LINE:
		property.usage = PROPERTY_USAGE_NO_EDITOR

## The trigger's sprite. Hidden at runtime unless collision shapes are visible ([code]Debug → Visible Collision Shapes[/codeb]).
var sprite: Sprite2D
## The trigger's UI. [TriggerEditor] will instantiate it.
var ui_path: String
var group_display: Label
var _center_anchor: Control
## The trigger's collision shape.
var _hitbox: CollisionShape2D
var _hitbox_display: TriggerHitboxDisplay

func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	_hitbox_display = NodeUtils.get_node_or_add(self, "TriggerHitboxDisplay", load("res://src/triggers/trigger_components/TriggerHitboxDisplay.gd"), NodeUtils.INTERNAL)
	_hitbox_display.z_index = -20
	_hitbox = NodeUtils.get_node_or_add(self, "Hitbox", CollisionShape2D, NodeUtils.INTERNAL)
	sprite = NodeUtils.get_node_or_add(self, "Sprite", Sprite2D, NodeUtils.INTERNAL)
	_hitbox.debug_color = Color("fff5006b")
	sprite.scale = Vector2.ONE * 0.2
	sprite.set_texture(DEFAULT_TRIGGER_TEXTURE)
	NodeUtils.get_node_or_add(self, "SingleUsageComponent", SingleUsageComponent, NodeUtils.INTERNAL)
	NodeUtils.connect_once(hitbox_shape_changed, _hitbox_display.update_shape)
	_center_anchor = NodeUtils.get_node_or_add(self, "Center Anchor", Control, NodeUtils.INTERNAL)
	group_display = NodeUtils.get_node_or_add(_center_anchor, "Group Display", Label, NodeUtils.INTERNAL)
	_set_hitbox_shape()
	move_child(_center_anchor, -1)


func _physics_process(_delta: float) -> void:
	sprite.visible = sprite_visible()
	if not get_parent() is GameplayRotateTrigger:
		if Engine.is_editor_hint() or LevelManager.player_camera == null:
			sprite.global_rotation = 0.0
			group_display.global_rotation = 0.0
		else:
			sprite.global_rotation = LevelManager.player_camera.global_rotation
	sprite.global_scale = Vector2.ONE * 0.2
	_center_anchor.rotation = sprite.rotation


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
