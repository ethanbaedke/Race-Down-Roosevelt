class_name TournamentMatchData extends Resource

@export var player_profiles:Array[Profile] = []
@export var ai_profiles:Array[Profile] = []
@export var is_up_next:bool = false

func get_all_profiles() -> Array[Profile]:
	
	var all_profiles:Array[Profile] = []
	all_profiles.append_array(player_profiles)
	all_profiles.append_array(ai_profiles)
	return all_profiles

# Fills profiles list with ai until it has 4 profiles.
func fill_with_ai() -> void:
	
	var num_ai_profiles:int = 4 - player_profiles.size()
	var new_ai_profiles:Array[Profile] = Globals.get_random_unique_ai_profiles(num_ai_profiles)
	for ai_profile:Profile in new_ai_profiles:
		ai_profiles.append(ai_profile)
