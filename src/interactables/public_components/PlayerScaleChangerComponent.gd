extends Component
class_name PlayerScaleChangerComponent

@export var player_scale: Player.PlayerScale


func _ready() -> void:
	parent.body_entered.connect(set_scale)


func set_scale(player: Player) -> void:
	player.player_scale = player_scale