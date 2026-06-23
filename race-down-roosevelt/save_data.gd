class_name SaveData extends Resource

@export var profiles:Array[Profile] = []

func save() -> void:
	
	if (ResourceSaver.save(self, Globals.SAVE_DATA_PATH) == OK):
		RdrLogger.log(self, "Data saved.")
	else:
		RdrLogger.log(self, "Data failed to save.")
