class_name RaceParameters extends Resource

@export var racer_objects:Array[RacerObject] = [null, null, null, null]
@export var include_ai_racers:bool = true

# Ensures there are no conflics with the current parameter setup.
func validate_parameters() -> bool:
	
	RdrLogger.log(self, "Beginning validation.")
	
	# If set to include ai racers, ensure no racers are null.
	if (include_ai_racers):
		for i:int in range(racer_objects.size()):
			if (racer_objects[i] == null):
				RdrLogger.log(self, "Validation failed: set to include ai-racers but found a null racer. Null racers should not exist if using AI racers.")
				racer_objects[i] = RacerObject.new()
	
	# Duplicate names is not considered invalid, we just handle fixing them here.
	handle_duplicate_names()
	
	# The racer array must have a size a four. Null entries are okay, and in some cases, expected.
	if (racer_objects.size() != 4):
		RdrLogger.error(self, "Validation failed: must contain exactly 4 racer objects, but " + str(racer_objects.size()) + " are present.")
		return false
	
	# Two racers should never have the same device index, unless it's -2, signaling that it's AI controlled.
	var device_index_dict:Dictionary = {}
	for i:int in range(racer_objects.size()):
		if (racer_objects[i] == null):
			continue
		var index:int = racer_objects[i].device_index
		if (index == -2):
			continue
		if (device_index_dict.has(index)):
			RdrLogger.error(self, "Validation failed: multiple racers are attempting to use device with index " + str(index) + ".")
			return false
		else:
			# True means nothing here. Just need the key to exist in the dictionary.
			device_index_dict[index] = true
	
	RdrLogger.log(self, "Validation succeeded.")
	return true

# Modifies the race parameters so no conflicts exits.
# This could involve removing racers.
func force_resolve_conflicts() -> void:
	
	RdrLogger.log(self, "Beginning conflict resolution.")
	
	# Add or remove racers until there are exactly four.
	if (racer_objects.size() < 4):
		for i:int in range(racer_objects.size(), 4):
			RdrLogger.warn(self, "Less than four racers exist, adding null racer.")
			racer_objects.append(null)
	if (racer_objects.size() > 4):
		for i:int in range(racer_objects.size() - 1, 3, -1):
			RdrLogger.warn(self, "More than four racers exist, removing last racer.")
			racer_objects.remove_at(i)
	
	# If set to include ai racers, replace any null racers with ai racer objects.
	if (include_ai_racers):
		for i:int in range(racer_objects.size()):
			if (racer_objects[i] == null):
				RdrLogger.log(self, "Replacing null racer with ai racer.")
				racer_objects[i] = RacerObject.new()
	
	# Ensure names are unique.
	handle_duplicate_names()
	
	# Remove racers attempting to use the same input device.
	var device_index_dict:Dictionary = {}
	for i:int in range(racer_objects.size()):
		if (racer_objects[i] == null):
			continue
		var index:int = racer_objects[i].device_index
		if (index == -2):
			continue
		if (device_index_dict.has(index)):
			RdrLogger.warn(self, "Multiple racers attempting to use device with index " + str(index) + ". Setting one of these racers to null.")
			racer_objects[i] = null
		else:
			# True means nothing here. Just need the key to exist in the dictionary.
			device_index_dict[index] = true
	
	RdrLogger.log(self, "Conflict resolution complete.")
			
func handle_duplicate_names() -> void:
	
	# If more than one racer has the same name, append numbering to the ends of subsequet racers names.
	var name_dict:Dictionary = {}
	for i:int in range(racer_objects.size()):
		if (racer_objects[i] == null || racer_objects[i].name.is_empty()):
			continue
		var name:String = racer_objects[i].name
		if (name_dict.has(name)):
			var new_name:String = name + " (" + str(name_dict[name]) + ")"
			RdrLogger.log(self, "Duplicate name detected: changing " + name + " to " + new_name + ".")
			racer_objects[i].name = new_name
			name_dict[name] += 1
		else:
			name_dict[name] = 1
