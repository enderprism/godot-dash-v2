extends Component
class_name GamemodeChangerComponent

enum GamemodeChange {
	BOTH,
	ONLY_INTERNAL,
	ONLY_DISPLAYED,
}

@export var gamemode: Player.Gamemode
@export var change: GamemodeChange


func _ready() -> void:
	parent.body_entered.connect(set_gamemode)


func set_gamemode(player: Player) -> void:
	match change:
		GamemodeChange.BOTH:
			player.internal_gamemode = gamemode
			player.displayed_gamemode = gamemode
			player.player_scale = player.player_scale # Run setter to make sure the wave has the right scale
		GamemodeChange.ONLY_INTERNAL:
			player.internal_gamemode = gamemode
			player.player_scale = player.player_scale # Run setter to make sure the wave has the right scale
		GamemodeChange.ONLY_DISPLAYED:
			player.displayed_gamemode = gamemode