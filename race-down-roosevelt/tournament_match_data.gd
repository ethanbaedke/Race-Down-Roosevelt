class_name TournamentMatchData extends Resource

# TODO: The profiles here will be loaded from the machine and there will be two copies. One here, and one on the save data resource.
# TODO: These lists should reference profile ids (integers that represent which profile on save data is being used here).
# TODO: Will need to handle a profile being removed and then a tournament being continued that uses the removed profile.
@export var player_profiles:Array[Profile] = []
@export var ai_profiles:Array[Profile] = []
@export var is_up_next:bool = false
# Filled out after a race is finished in the order the profiles finished in.
# TODO: Will need the same fixes mentioned above.
@export var finish_order:Array[Profile] = []

# These tell the match where to push winners and losers.
# TODO: Will need the same fixes mentioned above, since these objects will also be duplicated after loading.
# TODO: Should store targets as round and match indices.
@export var winner_match_target:TournamentMatchData = null
@export var loser_match_target:TournamentMatchData = null

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

# Pushes the winning and losing profiles to their next matches.
func push_profiles() -> void:
	
	if (finish_order.size() != 4):
		RdrLogger.fatal(self, push_profiles.get_method() + " expects finish order to be set with 4 profiles.")
		return
		
	if (winner_match_target != null):
		for i:int in range(2):
			if (player_profiles.find(finish_order[i]) != -1):
				winner_match_target.player_profiles.append(finish_order[i])
			else:
				winner_match_target.ai_profiles.append(finish_order[i])
	if (loser_match_target != null):
		for i:int in range(2, 4):
			if (player_profiles.find(finish_order[i]) != -1):
				loser_match_target.player_profiles.append(finish_order[i])
			else:
				loser_match_target.ai_profiles.append(finish_order[i])
