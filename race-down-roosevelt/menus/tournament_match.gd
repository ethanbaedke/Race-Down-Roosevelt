class_name TournamentMatch extends CenterContainer

@export var _profile_name_labels:Array[Label] = []
@export var _match_panel:PanelContainer = null

var _match_data:TournamentMatchData = null

func set_match_data(match_data:TournamentMatchData) -> void:
	
	_match_data = match_data
	_refresh_match()

func _refresh_match() -> void:
	
	if (_match_data == null):
		RdrLogger.error(self, "Cannot refresh match since match data is null.")
		return
	
	var match_profiles:Array[Profile] = _match_data.get_all_profiles()
	for i:int in range(match_profiles.size()):
		_profile_name_labels[i].text = match_profiles[i].name
		
	if (_match_data.is_up_next):
		_match_panel.self_modulate = Color.GOLDENROD
