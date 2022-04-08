extends Control

var currentPlayer
onready var music_players = $Musics.get_children()

onready var main_menu = preload("res://src/MainMenu/MainMenu.tscn")
onready var level = preload("res://src/Level/Level.tscn")
onready var change_level = preload("res://src/EndLevel/EndLevel.tscn")
onready var credits = preload("res://src/Credits/Credits.tscn")
onready var game_over = preload("res://src/GameOver/GameOver.tscn")

onready var viewport = $ViewportContainer/Viewport

var current_level_number = 0
var nb_coins = 0

var current_player
var current_scene setget set_scene

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	_run_main_menu()

func _process(_delta):
	if Input.is_action_pressed("quit"):
		get_tree().quit()

func _on_quit_game():
	get_tree().quit()

func _on_start_game():
	_load_level()

func _on_show_credits():
	_run_credits(true)

func _on_show_main_menu():
	_run_main_menu()

func set_scene(new_scene):
	if current_scene:
		viewport.remove_child(current_scene)
		current_scene.queue_free()

	current_scene = new_scene
	viewport.add_child(current_scene)

func _load_level():
	var scene = level.instance()
	scene.init(current_level_number, nb_coins)

	scene.connect("end_of_level", self, "_on_end_of_level")
	scene.connect("game_over", self, "_on_game_over")

	self.current_scene = scene

func _on_end_of_level():
	if current_level_number + 1 >= 2:
		# Win
		_run_credits(false)
	else:
		_load_end_level()

func first_level():
	return current_level_number == 0

func _on_game_over():
	var scene = game_over.instance()

	scene.connect("restart", self, "_on_restart_level")
	scene.connect("quit", self, "_on_quit_game")

	self.current_scene = scene

func _on_restart_level():
	_load_level()

func _on_restart_select_level():
	_load_end_level()

func _load_end_level():
	var scene = change_level.instance()
	scene.init(current_level_number, nb_coins)

	scene.connect("next_level", self, "_on_next_level")

	self.current_scene = scene

func _on_next_level():
	current_level_number += 1
	changeMusicTrack(music_players[current_level_number%len(music_players)])
	_load_level()

func _run_credits(can_go_back):
	var scene = credits.instance()

	scene.set_back(can_go_back)	
	if can_go_back:
		scene.connect("back", self, "_on_show_main_menu")

	self.current_scene = scene

func _run_main_menu():
	var scene = main_menu.instance()

	changeMusicTrack(music_players[0])

	scene.connect("start_game", self, "_on_start_game")
	scene.connect("quit_game", self, "_on_quit_game")
	scene.connect("show_credits", self, "_on_show_credits")

	self.current_scene = scene

func changeMusicTrack(newPlayer):
	if currentPlayer != newPlayer:
		for mp in music_players:
			mp.stop()

		newPlayer.play()
		currentPlayer = newPlayer
