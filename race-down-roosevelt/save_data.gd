class_name SaveData extends Resource

@export var profiles:Array[Profile] = []

@export var in_progress_tournaments:Array[TournamentState] = []

@export var music_volume:float = 1.0
signal music_volume_changed(value:float)
func set_music_volume(value:float) -> void:
	
	music_volume = value
	music_volume_changed.emit(value)

@export var sfx_volume:float = 1.0
signal sfx_volume_changed(value:float)
func set_sfx_volume(value:float) -> void:
	
	sfx_volume = value
	sfx_volume_changed.emit(value)

enum GraphicsQuality {
	LOW,
	MEDIUM,
	HIGH
}
@export var graphics_quality:GraphicsQuality = GraphicsQuality.MEDIUM
signal graphics_quality_changed(value:GraphicsQuality)
func set_graphics_quality(value:GraphicsQuality) -> void:
	
	graphics_quality = value
	graphics_quality_changed.emit(value)

enum AIDifficulty {
	LOW,
	MEDIUM,
	HIGH,
}
@export var ai_difficulty:AIDifficulty = AIDifficulty.MEDIUM
signal ai_difficulty_changed(value:AIDifficulty)
func set_ai_difficulty(value:AIDifficulty) -> void:
	
	ai_difficulty = value
	ai_difficulty_changed.emit(value)

func save() -> void:
	
	if (ResourceSaver.save(self, Globals.SAVE_DATA_PATH) == OK):
		RdrLogger.log(self, "Data saved.")
	else:
		RdrLogger.log(self, "Data failed to save.")
