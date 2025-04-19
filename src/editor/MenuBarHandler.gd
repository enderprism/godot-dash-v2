extends Node
class_name MenuBarHandler

@export var edit_handler: EditHandler
@export var open_dialog: FileDialog
@export var import_dialog: FileDialog
@export var save_as_dialog: FileDialog
@export var export_dialog: FileDialog
@export var save_changes_before_opening_dialog: ConfirmationDialog
@export var corrupted_level_dialog: AcceptDialog
@export var level_already_exists_dialog: ConfirmationDialog

@onready var editor := get_parent() as EditorScene


func _ready() -> void:
	save_changes_before_opening_dialog.add_button("Don't Save", false, "dontsave")
	save_as_dialog.root_subfolder = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	export_dialog.root_subfolder = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)


func _on_level_index_pressed(index:int) -> void:
	match index:
		0: # New
			if editor.level_was_modified():
				save_changes_before_opening_dialog.show()
				save_changes_before_opening_dialog.set_meta("next", _new_level)
			else:
				_new_level()
		1: # Open
			open_dialog.show()
		2: # Import
			import_dialog.show()
		3: # Save
			_save_level()
		4: # Save As
			save_as_dialog.show()
		5: # Export
			if editor.level.has_meta("packed_file_name"):
				export_dialog.set_current_file(editor.level.get_meta("packed_file_name").get_basename())
			export_dialog.show()


func _new_level() -> void:
	var new_level := LevelProps.new()
	editor.level.add_sibling(new_level)
	editor.level.queue_free()
	editor.level = new_level


func _open_level(path: String) -> void:
	if LevelManager.level_playing:
		editor._on_playtest_pressed()
		_open_level.call_deferred(path)
		return
	ResourceLoader.load_threaded_request(path, "PackedScene")
	var level_packed := ResourceLoader.load_threaded_get(path) as PackedScene
	var level = level_packed.instantiate() as LevelProps
	var song_file_path: String
	if level.song_path.begins_with("uid"):
		song_file_path = ResourceUID.get_id_path(ResourceUID.text_to_id(level.song_path)).get_file()
	else:
		song_file_path = level.song_path.get_file()
	level.song_path = "user://created_levels/songs/" + song_file_path
	level.set_meta("packed_file_path", path)
	editor.level.add_sibling(level)
	editor.level.queue_free()
	editor.level = level
	edit_handler.selection.clear()


func _import_level(path: String, keep_original: bool) -> void:
	var reader = ZIPReader.new()
	reader.open(path)
	var files := reader.get_files()
	var level_dir := DirAccess.open("user://created_levels/levels")
	var song_dir := DirAccess.open("user://created_levels/songs")
	var level_path: String
	if not "tscn" in Array(files).map(func(file): return file.get_extension()):
		corrupted_level_dialog.show()
		return
	for file_path in files:
		var dir := level_dir if file_path.ends_with(".tscn") else song_dir
		var buffer := reader.read_file(file_path)
		if dir == level_dir:
			level_path = dir.get_current_dir().path_join(file_path)
			if FileAccess.file_exists(level_path):
				level_already_exists_dialog.show()
				level_already_exists_dialog.confirmed.connect(_import_overwrite.bind(level_path, buffer))
				await level_already_exists_dialog.visibility_changed
			else:
				var file = FileAccess.open(dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
				file.store_buffer(buffer)
		else:
			var file = FileAccess.open(dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
			file.store_buffer(buffer)
	reader.close()
	if not keep_original:
		OS.move_to_trash(path)
	_open_level(level_path)


func _import_overwrite(level_path: String, buffer: PackedByteArray) -> void:
	var file = FileAccess.open(level_path, FileAccess.WRITE)
	file.store_buffer(buffer)


func _save_level() -> void:
	if not editor.level.has_meta("packed_file_name"):
		save_as_dialog.show()
		return # _save_level will get called again by the dialog
	var file_name = editor.level.get_meta("packed_file_name")
	if not LevelManager.level_playing:
		# The level is saved before starting playtest, but here the creator isn't playtesting.
		var selection_backup := edit_handler.selection.duplicate()
		edit_handler.selection.map(EditHandler.remove_selection_highlight)
		edit_handler.selection.clear()
		LevelManager.editor_level_backup.pack(editor.level)
		edit_handler.selection = selection_backup
		edit_handler.selection.map(EditHandler.add_selection_highlight)
	ResourceSaver.save(LevelManager.editor_level_backup, "user://created_levels/levels/" + file_name)
	Toasts.new_toast("Saved level " + file_name.get_basename())


func _on_open_level_dialog_file_selected(path:String) -> void:
	if editor.level_was_modified():
		save_changes_before_opening_dialog.show()
		save_changes_before_opening_dialog.set_meta("next", _open_level)
		save_changes_before_opening_dialog.set_meta("next_path", path)
	else:
		_open_level(path)


func _on_import_and_open_level_dialog_file_selected(path:String) -> void:
	if editor.level_was_modified():
		save_changes_before_opening_dialog.show()
		save_changes_before_opening_dialog.set_meta("next", _import_level)
		save_changes_before_opening_dialog.set_meta("next_path", path)
		save_changes_before_opening_dialog.set_meta("next_options", import_dialog.get_selected_options()["Keep original level file"])
	else:
		_import_level(path, import_dialog.get_selected_options()["Keep original level file"])


func _on_save_level_as_dialog_file_selected(path:String) -> void:
	editor.level.set_meta("packed_file_name", path.get_file())
	_save_level()


func _on_save_changes_before_opening_confirmed() -> void:
	_save_level()
	if save_changes_before_opening_dialog.get_meta("next") == _import_level:
		save_changes_before_opening_dialog.get_meta("next").call(save_changes_before_opening_dialog.get_meta("next_path"), save_changes_before_opening_dialog.get_meta("next_options"))
	elif save_changes_before_opening_dialog.get_meta("next") != _new_level:
		save_changes_before_opening_dialog.get_meta("next").call(save_changes_before_opening_dialog.get_meta("next_path"))
	else:
		save_changes_before_opening_dialog.get_meta("next").call()


func _on_save_changes_before_opening_custom_action(action:StringName) -> void:
	match action:
		&"dontsave":
			if save_changes_before_opening_dialog.get_meta("next") == _import_level:
				save_changes_before_opening_dialog.get_meta("next").call(save_changes_before_opening_dialog.get_meta("next_path"), save_changes_before_opening_dialog.get_meta("next_options"))
			elif save_changes_before_opening_dialog.get_meta("next") != _new_level:
				save_changes_before_opening_dialog.get_meta("next").call(save_changes_before_opening_dialog.get_meta("next_path"))
			else:
				save_changes_before_opening_dialog.get_meta("next").call()
			save_changes_before_opening_dialog.hide()


func _on_export_level_dialog_file_selected(path:String) -> Error:
	var writer = ZIPPacker.new()
	var err = writer.open(path)
	if err != OK:
		return err
	var file_name := path.get_file().get_basename() + ".tscn"
	#section Level Pack
	writer.start_file(file_name)
	if not LevelManager.level_playing:
		# The level is saved before starting playtest, but here the creator isn't playtesting.
		var selection_backup := edit_handler.selection.duplicate()
		edit_handler.selection.map(EditHandler.remove_selection_highlight)
		edit_handler.selection.clear()
		LevelManager.editor_level_backup.pack(editor.level)
		edit_handler.selection = selection_backup
		edit_handler.selection.map(EditHandler.add_selection_highlight)
	ResourceSaver.save(LevelManager.editor_level_backup, OS.get_temp_dir().path_join(file_name)) # We don't care about overwriting a tempfile.
	var level_bytes := FileAccess.get_file_as_bytes(OS.get_temp_dir().path_join(file_name))
	writer.write_file(level_bytes)
	writer.close_file()
	#endsection
	#section Song Pack
	if editor.level.song_path.get_file() != "":
		file_name = editor.level.song_path.get_file()
		writer.start_file(file_name)
		var song_bytes := FileAccess.get_file_as_bytes(editor.level.song_path)
		writer.write_file(song_bytes)
		writer.close_file()
	writer.close()
	Toasts.new_toast("Exported level " + path.get_file().get_basename() + " in directory " + path.get_base_dir(), 2.0)
	return OK

