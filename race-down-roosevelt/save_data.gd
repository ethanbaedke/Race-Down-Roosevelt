class_name SaveData extends Resource

@export var profiles:Array[Profile] = []

@export var in_progress_tournements:Array[TournementState] = []

func save() -> void:
	
	if (ResourceSaver.save(self, Globals.SAVE_DATA_PATH) == OK):
		RdrLogger.log(self, "Data saved.")
	else:
		RdrLogger.log(self, "Data failed to save.")
