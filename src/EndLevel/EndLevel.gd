extends Control

signal next_level

var level_number
var nb_coins

onready var level_label = $CenterContainer/VBoxContainer/CenterContainer/HBoxContainer/LevelNumber
onready var coin_label = $CenterContainer/VBoxContainer/CenterContainer2/HBoxContainer2/CoinsNumber


func _ready():
	assert(
		level_number != null and nb_coins != null,
		"init must be called before creating EndLevel scene"
	)
	level_label.text = str(level_number + 1)
	coin_label.text = str(nb_coins)


func init(level_number, nb_coins):
	self.level_number = level_number
	self.nb_coins = nb_coins


func _on_NextLevelButton_pressed():
	emit_signal("next_level")
