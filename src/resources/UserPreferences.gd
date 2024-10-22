class_name UserPreferences extends Resource

@export_group("Graphics")
@export_range(0, 60, 1, "or_greater") var max_fps: int = 60
@export var game_resolution: Vector2
@export_storage var game_scale_factor := 1.0
@export var fullscreen: bool

@export_group("Audio")
@export_range(0, 1, .05) var music_audio_level: float = 1.0
@export_range(0, 1, .05) var game_sfx_audio_level: float = 1.0
@export_range(0, 1, .05) var in_level_sfx_audio_level: float = 1.0

@export_group("Editor")
@export var selection_zone_color := Color.GREEN
@export_range(0, 1, .05) var selection_zone_fill_alpha := 0.2
@export var trigger_hitbox_color := Color.CYAN
@export_range(0, 1, .05) var trigger_hitbox_fill_alpha := 0.2


func save() -> void:
	ResourceSaver.save(self, "user://user_prefs.tres")


static func load_or_create() -> UserPreferences:
	var user_preferences: UserPreferences = load("user://user_prefs.tres") as UserPreferences
	if !user_preferences:
		user_preferences = UserPreferences.new()
	return user_preferences