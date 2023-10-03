extends Node2D


func _ready():
	Globals.reset_state()
	Dialogic.start("res://story/start.dtl")
	await get_tree().process_frame
	Globals.setDialogicVisibility(true)

