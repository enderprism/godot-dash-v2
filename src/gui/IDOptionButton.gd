extends OptionButton

signal id_selected(id: int)


func _ready() -> void:
	item_selected.connect(_on_item_selected)


func _on_item_selected(index: int) -> void:
	id_selected.emit(get_item_id(index))