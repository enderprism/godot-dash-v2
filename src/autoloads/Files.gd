extends Node

signal file_loaded(path: String)
signal files_loaded(paths: PackedStringArray)

const SINGLE_FILE := 1

@export var load_dialog: FileDialog
@export var import_and_load_dialog: FileDialog


func load(filters: PackedStringArray, root: String) -> void:
	load_dialog.filters = filters
	load_dialog.root_subfolder = root
	load_dialog.show()
	NodeUtils.disconnect_all(load_dialog.canceled)
	NodeUtils.disconnect_all(load_dialog.file_selected)
	load_dialog.canceled.connect(func(): file_loaded.emit(""))
	load_dialog.file_selected.connect(func(path): file_loaded.emit(path))


func import_and_load(filters: PackedStringArray, root: String, import_to: String, options: int) -> void:
	import_and_load_dialog.filters = filters
	import_and_load_dialog.root_subfolder = root
	import_and_load_dialog.show()
	NodeUtils.disconnect_all(import_and_load_dialog.canceled)
	NodeUtils.disconnect_all(import_and_load_dialog.file_selected)
	NodeUtils.disconnect_all(import_and_load_dialog.files_selected)
	import_and_load_dialog.canceled.connect(func(): file_loaded.emit(""))
	if options & SINGLE_FILE:
		import_and_load_dialog.file_selected.connect(func(path): _import(PackedStringArray([path]), import_to); file_loaded.emit(path))
	else:
		import_and_load_dialog.files_selected.connect(func(paths): _import(paths, import_to); files_loaded.emit(paths))


func _import(file_paths: PackedStringArray, import_to: String) -> void:
	for path in file_paths:
		DirAccess.copy_absolute(path, import_to + path.get_file())

