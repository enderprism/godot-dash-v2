extends Interactable
class_name TriggerInteractable


func _ready() -> void:
	super()
	body_entered.connect(func(body): interacted.emit(body))
