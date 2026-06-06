class_name PlayerCountSelection extends Control

signal count_chosen(count:int)

@onready var _button_1p:Button = $MarginContainer/VBoxContainer/Button1P
@onready var _button_2p:Button = $MarginContainer/VBoxContainer/Button2P
@onready var _button_3p:Button = $MarginContainer/VBoxContainer/Button3P
@onready var _button_4p:Button = $MarginContainer/VBoxContainer/Button4P

func _ready() -> void:

	_button_1p.pressed.connect(func() -> void:
		RdrLogger.log(self, "Player count chosen: 1 player.")
		count_chosen.emit(1)
	)
	_button_2p.pressed.connect(func() -> void:
		RdrLogger.log(self, "Player count chosen: 2 player.")
		count_chosen.emit(2)
	)
	_button_3p.pressed.connect(func() -> void:
		RdrLogger.log(self, "Player count chosen: 3 player.")
		count_chosen.emit(3)
	)
	_button_4p.pressed.connect(func() -> void:
		RdrLogger.log(self, "Player count chosen: 4 player.")
		count_chosen.emit(4)
	)
