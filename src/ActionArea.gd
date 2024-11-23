@tool
extends Area2D
class_name ActionArea

enum Action {
	STOP_JUMP,
	STOP_DASH,
}

@export var _action: Action:
	set(value):
		_action = value
		if is_inside_tree(): _refresh_letter()

var _hitbox: CollisionShape2D
var _player: Player:
	get(): return LevelManager.player if not Engine.is_editor_hint() else null
var _letter: Label
var _ninepatchrect: NinePatchRect

func _ready() -> void:
	body_entered.connect(_on_player_enter)
	_letter = get_node_or_null("Letter")
	_ninepatchrect = get_node_or_null("NinePatchRect")
	_hitbox = $Hitbox

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or get_tree().debug_collisions_hint:
		_hitbox.debug_color = Color("00ff0000")
		_ninepatchrect.visible = true
		_letter.visible = true
	else:
		_hitbox.debug_color = Color("00ff0033")
		_ninepatchrect.visible = false
		_letter.visible = false
	if has_node("NinePatchRect"):
		_ninepatchrect.scale = Vector2(0.25, 0.25) / scale.abs()
		_ninepatchrect.size = Vector2(512.0, 512.0) * scale.abs()
		_ninepatchrect.position = -_ninepatchrect.size/2
		_ninepatchrect.pivot_offset = _ninepatchrect.size/2
	if has_node("Letter"):
		_letter.scale = Vector2(0.25, 0.25) / scale.abs()
		_letter.size = Vector2(512.0, 512.0) * scale.abs()
		_letter.position = -_letter.size/2
		_letter.pivot_offset = _letter.size/2

func _on_player_enter(_body: Node2D) -> void:
	match _action:
		Action.STOP_JUMP:
			_player.jump_hold_disabled = true
		Action.STOP_DASH:
			_player.stop_dash()

func _refresh_letter() -> void:
	match _action:
		Action.STOP_JUMP:
			_letter.text = "j"
		Action.STOP_DASH:
			_letter.text = "s"
