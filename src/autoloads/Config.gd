extends Node

var config := UserPreferences.load_or_create()

func _notification(what):
	if config.mute_game_on_unfocus:
		if what == NOTIFICATION_APPLICATION_FOCUS_IN:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), linear_to_db(config.master_audio_level))
		elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), linear_to_db(0.0))
