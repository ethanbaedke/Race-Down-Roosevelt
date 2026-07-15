class_name TournamentState extends Resource

@export var tournament_name:String = "New Tournament"

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

@export var round_index:int = -1
@export var match_index:int = 0

@export var winner:Profile = null

func get_next_match() -> TournamentMatchData:
	
	return get_match(round_index, match_index)

func get_match(target_round_index:int, target_match_index:int) -> TournamentMatchData:
	
	match (target_round_index):
		-1:
			return null
		0:
			return winners_round_1[target_match_index]
		1:
			return winners_round_2[target_match_index]
		2:
			return winners_round_3[target_match_index]
		3:
			return winners_round_4[target_match_index]
		4:
			return losers_round_1[target_match_index]
		5:
			return losers_round_2[target_match_index]
		6:
			return losers_round_3[target_match_index]
		7:
			return losers_round_4[target_match_index]
		8:
			return losers_round_5[target_match_index]
		9:
			return final_round[target_match_index]
		_:
			return null

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
	
	# Name the tournament based on the current date and time.
	tournament_name = Time.get_datetime_string_from_system(false, true)
	
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
	var previous_match:TournamentMatchData = get_next_match()
	if (previous_match != null):
		previous_match.is_up_next = false
		_push_match_profiles(previous_match)
	
	var all_rounds:Array[Array] = get_all_rounds()
	
	if (round_index != -1 && match_index < all_rounds[round_index].size() - 1):
		match_index += 1
	elif (round_index < all_rounds.size() - 1):
		round_index += 1
		match_index = 0
	else:
		# Tournament over.
		winner = final_round[0].finish_order[0]
		return
	
	all_rounds[round_index][match_index].is_up_next = true
	
	# If the next match has no players, set a random profile order (for winners/losers) and skip it.
	var next_match:TournamentMatchData = get_next_match()
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
	
	# WINNERS ROUND 1
	for i:int in range(8):
		winners_round_1[i].winner_match_target_round = 1
		winners_round_1[i].loser_match_target_round = 4
		
	winners_round_1[0].winner_match_target_match = 0
	winners_round_1[0].loser_match_target_match = 0
	
	winners_round_1[1].winner_match_target_match = 0
	winners_round_1[1].loser_match_target_match = 1
	
	winners_round_1[2].winner_match_target_match = 1
	winners_round_1[2].loser_match_target_match = 0
	
	winners_round_1[3].winner_match_target_match = 1
	winners_round_1[3].loser_match_target_match = 1
	
	winners_round_1[4].winner_match_target_match = 2
	winners_round_1[4].loser_match_target_match = 2
	
	winners_round_1[5].winner_match_target_match = 2
	winners_round_1[5].loser_match_target_match = 3
	
	winners_round_1[6].winner_match_target_match = 3
	winners_round_1[6].loser_match_target_match = 2
	
	winners_round_1[7].winner_match_target_match = 3
	winners_round_1[7].loser_match_target_match = 3
	
	# WINNERS ROUND 2
	for i:int in range(4):
		winners_round_2[i].winner_match_target_round = 2
		winners_round_2[i].loser_match_target_round = 5
	
	winners_round_2[0].winner_match_target_match = 0
	winners_round_2[0].loser_match_target_match = 0
	
	winners_round_2[1].winner_match_target_match = 0
	winners_round_2[1].loser_match_target_match = 3
	
	winners_round_2[2].winner_match_target_match = 1
	winners_round_2[2].loser_match_target_match = 0
	
	winners_round_2[3].winner_match_target_match = 1
	winners_round_2[3].loser_match_target_match = 3
	
	# WINNERS ROUND 3
	for i:int in range(2):
		winners_round_3[i].winner_match_target_round = 3
		winners_round_3[i].loser_match_target_round = 6
	
	winners_round_3[0].winner_match_target_match = 0
	winners_round_3[0].loser_match_target_match = 0
	
	winners_round_3[1].winner_match_target_match = 0
	winners_round_3[1].loser_match_target_match = 2
	
	# WINNERS ROUND 4
	winners_round_4[0].winner_match_target_round = 9
	winners_round_4[0].loser_match_target_round = 7
	
	winners_round_4[0].winner_match_target_match = 0
	winners_round_4[0].loser_match_target_match = 1
	
	# LOSERS ROUND 1
	for i:int in range(4):
		losers_round_1[i].winner_match_target_round = 5
	
	losers_round_1[0].winner_match_target_match = 1
	losers_round_1[1].winner_match_target_match = 1
	losers_round_1[2].winner_match_target_match = 2
	losers_round_1[3].winner_match_target_match = 2
	
	# LOSERS ROUND 2
	for i:int in range(4):
		losers_round_2[i].winner_match_target_round = 6
	
	losers_round_2[0].winner_match_target_match = 0
	losers_round_2[1].winner_match_target_match = 1
	losers_round_2[2].winner_match_target_match = 1
	losers_round_2[3].winner_match_target_match = 2
	
	# LOSERS ROUND 3
	for i:int in range(3):
		losers_round_3[i].winner_match_target_round = 7
	
	losers_round_3[0].winner_match_target_match = 0
	losers_round_3[1].winner_match_target_match = 0
	losers_round_3[2].winner_match_target_match = 1
	
	# LOSERS ROUND 4
	for i:int in range(2):
		losers_round_4[i].winner_match_target_round = 8
	
	losers_round_4[0].winner_match_target_match = 0
	losers_round_4[1].winner_match_target_match = 0
	
	# LOSERS ROUND 5
	losers_round_5[0].winner_match_target_round = 9
	losers_round_5[0].winner_match_target_match = 0

# Pushes the winning and losing racer profiles to their next matches.
func _push_match_profiles(tm:TournamentMatchData) -> void:
	
	if (tm.finish_order.size() != 4):
		RdrLogger.fatal(self, _push_match_profiles.get_method() + " expects matches finish order to be set with 4 profiles.")
		return
		
	if (tm.winner_match_target_round != -1):
		var winner_match_target:TournamentMatchData = get_match(tm.winner_match_target_round, tm.winner_match_target_match)
		for i:int in range(2):
			if (tm.player_profiles.find(tm.finish_order[i]) != -1):
				winner_match_target.player_profiles.append(tm.finish_order[i])
			else:
				winner_match_target.ai_profiles.append(tm.finish_order[i])
	if (tm.loser_match_target_round != -1):
		var loser_match_target:TournamentMatchData = get_match(tm.loser_match_target_round, tm.loser_match_target_match)
		for i:int in range(2, 4):
			if (tm.player_profiles.find(tm.finish_order[i]) != -1):
				loser_match_target.player_profiles.append(tm.finish_order[i])
			else:
				loser_match_target.ai_profiles.append(tm.finish_order[i])

func _init() -> void:
	
	_initialize_match_targets()
