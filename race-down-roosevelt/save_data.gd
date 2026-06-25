class_name SaveData extends Resource

@export var profiles:Array[Profile] = []

@export var in_progress_tournaments:Array[TournamentState] = []

func save() -> void:
	
	# TESTING: Don't save tournaments.
	in_progress_tournaments.clear()
	
	if (ResourceSaver.save(self, Globals.SAVE_DATA_PATH) == OK):
		RdrLogger.log(self, "Data saved.")
	else:
		RdrLogger.log(self, "Data failed to save.")
