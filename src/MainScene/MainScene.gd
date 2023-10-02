extends Node2D


func _ready():
	Globals.reset_state()
	Dialogic.start("res://story/start.dtl")


