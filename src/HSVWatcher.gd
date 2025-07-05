extends Node2D
class_name HSVWatcher


@export_storage var hsv_shift: Array[float]
@export_storage var strength: float = 1.0
@export_storage var alpha: float = 1.0


func _ready() -> void:
	# Avoid using the parent's modulate if the modulate is already set.
	# This happens when a scene with HSVWatchers with set up modulates is loaded.
	
	if not get_parent().has_meta("_has_hsvwatcher"):
		modulate = get_parent().modulate
	get_parent().set_meta("_has_hsvwatcher", true)
	hsv_shift.resize(3)


func _process(_delta: float) -> void:
	if has_node("SelectionHighlight"):
		get_parent().modulate = modulate
		return
	var shifted_modulate := modulate
	shifted_modulate.h = fmod(shifted_modulate.h + hsv_shift[0], 1.0)
	shifted_modulate.s += hsv_shift[1]
	shifted_modulate.v += hsv_shift[2]
	get_parent().modulate = shifted_modulate * strength
	get_parent().modulate.a = alpha
