class_name RoadSpawnTable extends Resource

# Key is road row packed scene reference, value is weight for spawning (spawn chance relative to other weights).
@export var road_rows:Array[WeightedTableEntry] = []

# Expects at least one road row to exist with a weight >0.
# Returns the index of the road row in the list that should be spawned.
func get_random_road_row_index_weighted() -> int:
	
	if (road_rows.size() == 0):
		RdrLogger.fatal(self, get_random_road_row_index_weighted.get_method() + " expects at least one road row to exist.")
		return -1
	
	var total_weight:int = 0
	for entry:WeightedTableEntry in road_rows:
		total_weight += entry.weight
		
	if (total_weight == 0):
		RdrLogger.fatal(self, get_random_road_row_index_weighted.get_method() + " expects at least one road row to have a weight greater than 0.")
		return -1
	
	var total_counter:int = 0
	var target:int = randi_range(0, total_weight - 1)
	for i:int in road_rows.size():
		var entry:WeightedTableEntry = road_rows[i]
		var local_counter:int = 0
		while (local_counter < entry.weight):
			if (total_counter == target):
				return i
			local_counter += 1
			total_counter += 1
	
	RdrLogger.fatal(self, "An unexpected error occured during " + get_random_road_row_index_weighted.get_method())
	return -1

# Ensures there are no conflics with the current table setup.
func validate_parameters() -> bool:

	RdrLogger.log(self, "Beginning validation.")

	# At least one road row should exist to spawn.
	if (road_rows.size() < 1):
		RdrLogger.error(self, "Validation failed: list of spawnable road rows is empty. Must have at least one road row to spawn.")
		return false
	
	# Ensure at least one road row has a weight > 0.
	var valid_weight_exists:bool = false
	for entry:WeightedTableEntry in road_rows:
		if (entry.weight > 0):
			valid_weight_exists = true
	if (!valid_weight_exists):
		RdrLogger.error(self, "Validation failed: At least one road row must have a weight greater than 0.")
		return false
	
	# Throw a warning if any weight is zero, meaning the road row will never be spawned.
	for entry:WeightedTableEntry in road_rows:
		if (entry.weight <= 0):
			RdrLogger.warn(self, entry.scene.get_state().get_node_name(0) + " in road rows list has weight " + str(entry.weight) + ", so it will never be spawned.")
	
	# Ensure all scenes in the table exist and are of the road row type.
	for entry:WeightedTableEntry in road_rows:
		if (entry.scene == null):
			RdrLogger.error(self, "Validation failed: At least one road row scene in the table is null.")
			return false
		var scene:Object = entry.scene.instantiate()
		if (scene is not RoadRow):
			var current_type:String = scene.get_class()
			if (scene.get_script() != null):
				current_type = scene.get_script().get_global_name()
			var expected_type:String = (RoadRow as GDScript).get_global_name()
			RdrLogger.error(self, "Validation failed: All road row scenes must be of type " + expected_type + ", but a scene of type " + current_type + " was found.")
			return false
		
	
	RdrLogger.log(self, "Validation succeeded.")
	return true

# Modifies the table so no conflicts exits.
func force_resolve_conflicts() -> void:
	
	RdrLogger.log(self, "Beginning conflict resolution.")
	
	# Remove any road rows with empty scenes or scenes that are not of the road row type.
	var i:int = 0
	while (i < road_rows.size()):
		var entry:WeightedTableEntry = road_rows[i]
		if (entry.scene == null):
			RdrLogger.warn(self, "A null scene was found. Removing table entry.")
			road_rows.remove_at(i)
			continue
		var scene:Object = entry.scene.instantiate()
		if (scene is not RoadRow):
			var current_type:String = scene.get_class()
			if (scene.get_script() != null):
				current_type = scene.get_script().get_global_name()
			var expected_type:String = (RoadRow as GDScript).get_global_name()
			RdrLogger.error(self, "All road row scenes must be of type " + expected_type + ", but a scene of type " + current_type + " was found. Removing table entry.")
			road_rows.remove_at(i)
			continue
		i += 1
	
	# Ensure at least one road row exists.
	if (road_rows.size() < 1):
		# No road rows exist, try to load the straight row.
		var straight_row:PackedScene = load("res://road/road_row_straight.tscn")
		if (straight_row != null):
			RdrLogger.warn(self, "List of spawnable road rows was empty, adding the straight road row.")
			var entry:WeightedTableEntry = WeightedTableEntry.new()
			entry.scene = straight_row
			road_rows.append(entry)
		else:
			RdrLogger.fatal(self, "List of spawnable road rows was empty and the straight road row could not be loaded.")
	
	# Ensure at least one road row has a weight > 0.
	var valid_weight_exists:bool = false
	for entry:WeightedTableEntry in road_rows:
		if (entry.weight > 0):
			valid_weight_exists = true
	if (!valid_weight_exists):
		RdrLogger.warn(self, "No road rows have a weight greater than 0. Setting the first road rows weight to 1.")
		road_rows[0].weight = 1
	
	RdrLogger.log(self, "Conflict resolution complete.")
