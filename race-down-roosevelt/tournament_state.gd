class_name TournamentState extends Resource

@export var winners_round_1:Array[TournamentMatchData] = [
	TournamentMatchData.new(),
	TournamentMatchData.new(),
	TournamentMatchData.new(),
	TournamentMatchData.new(),
	TournamentMatchData.new(),
	TournamentMatchData.new(),
	TournamentMatchData.new(),
	TournamentMatchData.new(),
]
@export var winners_round_2:Array[TournamentMatchData] = [
	TournamentMatchData.new(),
	TournamentMatchData.new(),
	TournamentMatchData.new(),
	TournamentMatchData.new(),
]
@export var winners_round_3:Array[TournamentMatchData] = [
	TournamentMatchData.new(),
	TournamentMatchData.new(),
]
@export var winners_round_4:Array[TournamentMatchData] = [
	TournamentMatchData.new(),
]
@export var losers_round_1:Array[TournamentMatchData] = [
	TournamentMatchData.new(),
	TournamentMatchData.new(),
	TournamentMatchData.new(),
	TournamentMatchData.new(),
]
@export var losers_round_2:Array[TournamentMatchData] = [
	TournamentMatchData.new(),
	TournamentMatchData.new(),
	TournamentMatchData.new(),
	TournamentMatchData.new(),
]
@export var losers_round_3:Array[TournamentMatchData] = [
	TournamentMatchData.new(),
	TournamentMatchData.new(),
	TournamentMatchData.new(),
]
@export var losers_round_4:Array[TournamentMatchData] = [
	TournamentMatchData.new(),
	TournamentMatchData.new(),
]
@export var losers_round_5:Array[TournamentMatchData] = [
	TournamentMatchData.new(),
]
@export var final_round:Array[TournamentMatchData] = [
	TournamentMatchData.new(),
]

var next_match:TournamentMatchData = null
var winner:Profile = null

var _match_index:int = -1
var _round_index:int = 0

func get_all_rounds() -> Array[Array]:
	
	return [
		winners_round_1,
		winners_round_2,
		winners_round_3,
		winners_round_4,
		losers_round_1,
		losers_round_2,
		losers_round_3,
		losers_round_4,
		losers_round_5,
		final_round
	]

func build_tournament(player_profiles:Array[Profile]) -> void:
	
	if (player_profiles.size() > 32):
		RdrLogger.error(self, "Tournament size capped at 32. Trimming excess player profiles.")
		player_profiles.resize(32)
	
	# Put players into round one.
	# Spread players out so if there's less than 32, as many matches have players as possible.
	var match_ind:int = 0
	for profile:Profile in player_profiles:
		winners_round_1[match_ind].player_profiles.append(profile)
		match_ind = (match_ind + 1) % winners_round_1.size()
	
	# Fill remaining slots with ai profiles.
	_fill_with_ai()
	
	go_to_next_match()

func go_to_next_match() -> void:
	
	# Handle the previous match ending.
	if (next_match != null):
		next_match.is_up_next = false
		next_match.push_profiles()
	
	var all_rounds:Array[Array] = get_all_rounds()
	
	if (_match_index < all_rounds[_round_index].size() - 1):
		_match_index += 1
	elif (_round_index < all_rounds.size() - 1):
		_round_index += 1
		_match_index = 0
	else:
		# Tournament over.
		winner = final_round[0].finish_order[0]
		return
	
	next_match = all_rounds[_round_index][_match_index]
	all_rounds[_round_index][_match_index].is_up_next = true
	
	# If the next match has no players, set a random profile order (for winners/losers) and skip it.
	if (next_match.player_profiles.size() == 0):
		next_match.finish_order = next_match.ai_profiles.duplicate()
		next_match.finish_order.shuffle()
		go_to_next_match()

# Fills empty profile slots on all matches with ai profiles.
func _fill_with_ai() -> void:
	
	for tournament_match:TournamentMatchData in winners_round_1:
		tournament_match.fill_with_ai()

# Tell all matches which matches they should send their winners/losers to.
func _initialize_match_targets() -> void:
	
	for i:int in range(winners_round_1.size()):
		winners_round_1[i].winner_match_target = winners_round_2[i * 0.5]
		winners_round_1[i].loser_match_target = losers_round_1[i * 0.5]
		
	for i:int in range(winners_round_2.size()):
		winners_round_2[i].winner_match_target = winners_round_3[i * 0.5]
		winners_round_2[i].loser_match_target = losers_round_2[i]
		
	for i:int in range(winners_round_3.size()):
		winners_round_3[i].winner_match_target = winners_round_4[i * 0.5]
		winners_round_3[i].loser_match_target = losers_round_3[0]
		
	winners_round_4[0].winner_match_target = final_round[0]
	winners_round_4[0].loser_match_target = losers_round_4[0]
	
	for i:int in range(losers_round_1.size()):
		losers_round_1[i].winner_match_target = losers_round_2[i]
		
	for i:int in range(losers_round_2.size()):
		losers_round_2[i].winner_match_target = losers_round_3[(i * 0.5) + 1]
		
	for i:int in range(losers_round_3.size()):
		losers_round_3[i].winner_match_target = losers_round_4[(i + 1) * 0.5]
		
	for i:int in range(losers_round_4.size()):
		losers_round_4[i].winner_match_target = losers_round_5[i * 0.5]
		
	losers_round_5[0].winner_match_target = final_round[0]

func _init() -> void:
	
	_initialize_match_targets()
