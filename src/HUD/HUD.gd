extends CanvasLayer

@onready var room_label = %RoomLabel
@onready var transition_buttons = %TransitionButtons
@onready var move_to_label = %MoveToLabel
@onready var conclude_buttons = %ConcludeButtons
@onready var conclude_label = %ConcludeLabel


func _ready() -> void:
	Globals.room_changed.connect(Callable(self, "_on_room_changed"))
	Globals.moving_changed.connect(Callable(self, "_on_moving_changed"))
	_on_room_changed(Globals.current_room)
	Memories.active_memory_added_always_fired.connect(Callable(self, "_on_active_memory_added"))
	Memories.active_memory_removed.connect(Callable(self, "_on_active_memory_removed"))
	update_conclude()

func _process(_delta):
	transition_buttons.visible = Dialogic.VAR.allow_moving > 0


func _on_room_changed(room: Globals.Room):
	var room_name = Globals.get_room_name(room)
	room_label.text = room_name
	update_transitions()


func update_transitions():
	var rooms = Globals.get_transitions()
	for child in transition_buttons.get_children():
		transition_buttons.remove_child(child)
	move_to_label.visible = not rooms.is_empty()
	for room in rooms:
		var button = Button.new()
		button.text = Globals.get_room_name(room)
		button.pressed.connect(Callable(self, "_on_room_button_pressed").bind(room))
		transition_buttons.add_child(button)

func _on_moving_changed(moving: bool) -> void:
	for child in transition_buttons.get_children():
		child.disabled = moving

func _on_room_button_pressed(room: Globals.Room) -> void:
	Globals.move_to_room(room)

func update_conclude_visibility():
	conclude_buttons.visible = not conclude_buttons.get_children().is_empty()
	conclude_label.visible = not conclude_buttons.get_children().is_empty()

func update_conclude():
	print("update_conclude")
	for child in conclude_buttons.get_children():
		conclude_buttons.remove_child(child)
	for memory_id in Memories.active_memories:
		_on_active_memory_added(Memories.get_memory(memory_id))
	update_conclude_visibility()

func _on_active_memory_added(memory: Dictionary, _x: int = 0, _y: int = 0) -> void:
	if memory.ending == "":
		return
	var button = Button.new()
	button.text = memory.ending_name
	button.pressed.connect(Callable(self, "_on_conclude_button_pressed").bind(memory.ending))
	conclude_buttons.add_child(button)
	update_conclude_visibility()

func _on_active_memory_removed(memory_id: String) -> void:
	print("on_active_memory_removed", memory_id)
	var memory = Memories.get_memory(memory_id)
	for child in conclude_buttons.get_children():
		if child.text == memory.ending_name:
			conclude_buttons.remove_child(child)
	update_conclude_visibility()

func _on_conclude_button_pressed(ending: String) -> void:
	Dialogic.start(ending)
