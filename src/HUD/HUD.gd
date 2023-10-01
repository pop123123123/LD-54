extends CanvasLayer

@onready var room_label = %RoomLabel
@onready var transition_buttons = %TransitionButtons


func _ready() -> void:
	Globals.room_changed.connect(Callable(self, "_on_room_changed"))
	_on_room_changed(Globals.current_room)


func _on_room_changed(room: Globals.Room):
	var room_name = Globals.get_room_name(room)
	room_label.text = room_name
	update_transitions()


func update_transitions():
	var rooms = Globals.get_transitions()
	for child in transition_buttons.get_children():
		transition_buttons.remove_child(child)
	for room in rooms:
		var button = Button.new()
		button.text = Globals.get_room_name(room)
		button.pressed.connect(Callable(self, "_on_room_button_pressed").bind(room))
		transition_buttons.add_child(button)


func _on_room_button_pressed(room: Globals.Room) -> void:
	Globals.move_to_room(room)
