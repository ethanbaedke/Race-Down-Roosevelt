class_name RoadSpawnTable extends Resource

# Key is road row packed scene reference, value is weight for spawning (spawn chance relative to other weights).
@export var road_rows:Dictionary[PackedScene, int] = {}

# Expects at least one road row to exist with a weight >0.
func get_random_road_row_weighted() -> PackedScene:
	
	if (road_rows.size() == 0):
		RdrLogger.fatal(self, get_random_road_row_weighted.get_method() + " expects at least one road row to exist.")
		return null
	
	var total_weight:int = 0
	for value:PackedScene in road_rows:
		total_weight += road_rows[value]
		
	if (total_weight == 0):
		RdrLogger.fatal(self, get_random_road_row_weighted.get_method() + " expects at least one road row to have a weight greater than 0.")
		return null
	
	var total_counter:int = 0
	var target:int = randi_range(0, total_weight - 1)
	for value:PackedScene in road_rows:
		var local_counter:int = 0
		while (local_counter < road_rows[value]):
			if (total_counter == target):
				return value
			local_counter += 1
			total_counter += 1
	
	RdrLogger.fatal(self, "An unexpected error occured during " + get_random_road_row_weighted.get_method())
	return null

# Ensures there are no conflics with the current table setup.
func validate_parameters() -> bool:

	RdrLogger.log(self, "Beginning validation.")

	# At least one road row should exist to spawn.
	if (road_rows.size() < 1):
		RdrLogger.error(self, "Validation failed: list of spawnable road rows is empty. Must have at least one road row to spawn.")
		return false
		
	# If there is only one road row, it's weight must be > 0.
	if (road_rows.size() == 1):
		# Only iterating here because I can't use road_rows[0].
		for value:PackedScene in road_rows:
			if (road_rows[value] <= 0):
				RdrLogger.error(self, "Only one road row is present to spawn, but its weight is " + str(road_rows[value]) + " and must be greater than 0.")
				return false
		
	# Throw a warning if any weight is zero, meaning the road row will never be spawned.
	for value:PackedScene in road_rows:
		if (road_rows[value] <= 0):
			RdrLogger.warn(self, value.get_state().get_node_name(0) + " in road rows list has weight " + str(road_rows[value]) + ", so it will never be spawned.")
		
	RdrLogger.log(self, "Validation succeeded.")
	return true

# Modifies the table so no conflicts exits.
func force_resolve_conflicts() -> void:
	
	RdrLogger.log(self, "Beginning conflict resolution.")
	
	# Ensure at least one road row exists.
	if (road_rows.size() < 1):
		# No road rows exist, try to load the straight row.
		var straight_row:PackedScene = load("res://road/road_row_straight.tscn")
		if (straight_row != null):
			RdrLogger.warn(self, "List of spawnable road rows was empty, adding the stright road row.")
			road_rows[straight_row] = 1
		else:
			RdrLogger.fatal(self, "List of spawnable road rows was empty and the straight road row could not be loaded.")
	
	# Ensure if only one road row exists, it has weight >0.
	if (road_rows.size() == 1):
		# Only iterating here because I can't use road_rows[0].
		for value:PackedScene in road_rows:
			if (road_rows[value] <= 0):
				RdrLogger.warn(self, "Only one road row is present to spawn, but its weight is " + str(road_rows[value]) + ". Setting its weight to 1.")
				road_rows[value] = 1
	
	RdrLogger.log(self, "Conflict resolution complete.")
