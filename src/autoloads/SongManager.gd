extends Node

var thread: Thread

var loaded_songs: Dictionary[String, AudioStream]


func load_song(path: String) -> AudioStream:
	var audio_stream: AudioStream
	if path.begins_with("uid"):
		audio_stream = load(path)
	else:
		match path.get_extension():
			"mp3":
				audio_stream = AudioStreamMP3.load_from_file(path)
			"wav":
				audio_stream = AudioStreamWAV.load_from_file(path)
			"ogg":
				audio_stream = AudioStreamOggVorbis.load_from_file(path)
			_:
				printerr("Song isn't of valid type")
	loaded_songs[path] = audio_stream
	return audio_stream


func load_song_threaded_request(path: String) -> Error:
	if path.is_empty() or path == null:
		return ERR_FILE_BAD_PATH
	if thread == null:
		thread = Thread.new()
	thread.wait_to_finish()
	return thread.start(load_song.bind(path))


func load_song_threaded_get(path: String) -> AudioStream:
	if path.is_empty() or path == null:
		printerr("Song path is empty")
		return null
	thread.wait_to_finish()
	return loaded_songs[path]


func unload_all() -> void:
	loaded_songs.clear()


func _exit_tree() -> void:
	if thread == null:
		return
	thread.wait_to_finish()
