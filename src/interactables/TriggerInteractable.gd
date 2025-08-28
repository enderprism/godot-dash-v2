extends Interactable
class_name TriggerInteractable


func _ready() -> void:
	super()
	body_entered.connect(func(player: Player): interacted.emit(player))
