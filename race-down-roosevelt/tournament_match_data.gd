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

# These define where this match should push its winners and losers
# The actual pushing will be handled by the tournement state. The values are just stored here.
# These values should NEVER be touched by this class.
@export var winner_match_target_round:int = -1
@export var winner_match_target_match:int = 0
@export var loser_match_target_round:int = -1
@export var loser_match_target_match:int = 0

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
