extends Node

var _spectrum := AudioServer.get_bus_effect_instance(AudioServer.get_bus_index(&"Music"), 0)

func get_volume() -> float:
	if LevelManager.in_editor and not LevelManager.level_playing:
		return 0
	return clamp(_spectrum.get_magnitude_for_frequency_range(0, 10000).length() * 3, 0, 0.4)