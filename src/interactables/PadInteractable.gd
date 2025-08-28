extends Interactable
class_name PadInteractable


func _ready() -> void:
	super()
	body_entered.connect(_add_to_player_queue)
	body_entered.connect(func(player: Player): interacted.emit(player))
	body_exited.connect(_remove_from_player_queue)


func _add_to_player_queue(body: Node2D) -> void:
	var player := body as Player
	player.pad_queue.push_front(self)


func _remove_from_player_queue(body: Node2D) -> void:
	var player := body as Player
	player.pad_queue.erase(self)
