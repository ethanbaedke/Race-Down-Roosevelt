class_name TournamentMenuRound extends Control

@export var winners_round_1:Array[TournamentMatch] = []
@export var winners_round_2:Array[TournamentMatch] = []
@export var winners_round_3:Array[TournamentMatch] = []
@export var winners_round_4:Array[TournamentMatch] = []
@export var losers_round_1:Array[TournamentMatch] = []
@export var losers_round_2:Array[TournamentMatch] = []
@export var losers_round_3:Array[TournamentMatch] = []
@export var losers_round_4:Array[TournamentMatch] = []
@export var losers_round_5:Array[TournamentMatch] = []
@export var final_round:Array[TournamentMatch] = []

func show_round(ts:TournamentState) -> void:
	
	for i:int in range(winners_round_1.size()):
		winners_round_1[i].set_match_data(ts.winners_round_1[i])
	for i:int in range(winners_round_2.size()):
		winners_round_2[i].set_match_data(ts.winners_round_2[i])
	for i:int in range(winners_round_3.size()):
		winners_round_3[i].set_match_data(ts.winners_round_3[i])
	for i:int in range(winners_round_4.size()):
		winners_round_4[i].set_match_data(ts.winners_round_4[i])
	for i:int in range(losers_round_1.size()):
		losers_round_1[i].set_match_data(ts.losers_round_1[i])
	for i:int in range(losers_round_2.size()):
		losers_round_2[i].set_match_data(ts.losers_round_2[i])
	for i:int in range(losers_round_3.size()):
		losers_round_3[i].set_match_data(ts.losers_round_3[i])
	for i:int in range(losers_round_4.size()):
		losers_round_4[i].set_match_data(ts.losers_round_4[i])
	for i:int in range(losers_round_5.size()):
		losers_round_5[i].set_match_data(ts.losers_round_5[i])
	for i:int in range(final_round.size()):
		final_round[i].set_match_data(ts.final_round[i])
	
	self.visible = true
