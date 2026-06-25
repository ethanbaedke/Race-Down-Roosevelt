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
	
	var all_rounds:Array[Array] = get_all_rounds()
	
	if (_match_index < all_rounds[_round_index].size() - 1):
		_match_index += 1
	elif (_round_index < all_rounds.size() - 1):
		_round_index += 1
		_match_index = 0
	else:
		# TODO: Tournement over.
		return
	
	if (next_match != null):
		next_match.is_up_next = false
	next_match = all_rounds[_round_index][_match_index]
	all_rounds[_round_index][_match_index].is_up_next = true
	
	# If the next match has no players, skip it.
	if (next_match.player_profiles.size() == 0):
		go_to_next_match()

# Fills empty profile slots on all matches with ai profiles.
func _fill_with_ai() -> void:
	
	for tournament_match:TournamentMatchData in winners_round_1:
		tournament_match.fill_with_ai()
