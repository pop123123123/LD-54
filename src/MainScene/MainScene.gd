extends Node2D


func _ready():
	Globals.reset_state()
	Dialogic.start("res://story/tests/test_idle.dtl")


