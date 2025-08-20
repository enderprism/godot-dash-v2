extends Interactable
class_name TriggerInteractable


func _ready() -> void:
	body_entered.connect(func(body): interacted.emit(body))
