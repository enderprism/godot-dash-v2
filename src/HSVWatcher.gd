extends Node2D
class_name HSVWatcher


var hsv_shift: PackedFloat64Array = PackedFloat64Array([0.0, 0.0, 0.0])


func _ready() -> void:
	modulate = get_parent().modulate


func _process(_delta: float) -> void:
	if has_node("SelectionHighlight"):
		get_parent().modulate = modulate
		return
	var shifted_modulate := modulate
	shifted_modulate.h = fmod(shifted_modulate.h + hsv_shift[0], 1.0)
	shifted_modulate.s += hsv_shift[1]
	shifted_modulate.v += hsv_shift[2]
	get_parent().modulate = shifted_modulate
