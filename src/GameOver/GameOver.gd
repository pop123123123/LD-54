extends Control

signal restart
signal quit

func _on_Restart_pressed():
	emit_signal("restart")

func _on_Quit_pressed():
	emit_signal("quit")
