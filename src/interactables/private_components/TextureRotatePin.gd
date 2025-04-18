@tool
extends Component
class_name TextureRotationPin

var _indicator_icon: Sprite2D


func _ready() -> void:
	_indicator_icon = parent.get_node("Sprites/IndicatorIcon")


func _process(_delta: float) -> void:
	if _indicator_icon == null:
		return
	if not Engine.is_editor_hint() and LevelManager.player_camera != null:
		if parent.has_node("GravityChangerComponent"):
			_indicator_icon.global_rotation = LevelManager.player.gameplay_rotation
		else:
			_indicator_icon.global_rotation = LevelManager.player_camera.rotation
	else:
		_indicator_icon.global_rotation = 0.0
	_indicator_icon.global_scale.x = abs(parent.scale.x)
	_indicator_icon.global_scale.y = abs(parent.scale.y)
