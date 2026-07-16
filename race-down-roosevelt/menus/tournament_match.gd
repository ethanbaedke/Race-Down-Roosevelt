class_name TournamentMatch extends CenterContainer

@export var _num_winners_to_highlight:int = 2

@export var _profile_containers:Array[PanelContainer] = []
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
		# Set name
		_profile_name_labels[i].text = match_profiles[i].name
		# Set color based on finish position.
		if (_match_data.finish_order.size() == 4):
			var finish_pos_ind:int = _match_data.finish_order.find(match_profiles[i])
			if (finish_pos_ind < _num_winners_to_highlight):
				_profile_containers[i].self_modulate = Color.DARK_GREEN
			else:
				_profile_containers[i].self_modulate = Color.DARK_RED

	if (_match_data.is_up_next):
		(_match_panel.get_theme_stylebox("panel", "") as StyleBoxFlat).bg_color = Color.GOLDENROD
