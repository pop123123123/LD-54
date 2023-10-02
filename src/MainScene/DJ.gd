extends Node

@onready var whitePastaReggae = get_node("whitePastaReggae") as AudioStreamPlayer
@onready var watiByNight = get_node("watiByNight") as AudioStreamPlayer
var current_player_index = 0

func _ready():
	_start_reggae()
	
func _start_reggae():
	whitePastaReggae.play();
	whitePastaReggae.volume_db = 0;

func _start_night_music():
	var tween = get_tree().create_tween()
	tween.tween_property(whitePastaReggae, "volume_db", Vector2(whitePastaReggae.volume_db, -80), 2)
	tween.tween_callback(func(): whitePastaReggae.stop(); watiByNight.volume_db=0; watiByNight.play())

func _restart_reggae():
	var tween = get_tree().create_tween()
	tween.tween_property(watiByNight, "volume_db", Vector2(watiByNight.volume_db, -80), 2)
	tween.tween_callback(func(): watiByNight.stop(); whitePastaReggae.volume_db=0; whitePastaReggae.play())
