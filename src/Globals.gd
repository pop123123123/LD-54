extends Node

signal room_changed(room: Room)
signal moving_changed(moving: bool)

enum Room {
	LOBBY,
	TOILET,
	GROOMING,
	CORRIDOR,
	SUPPLY_ROOM,
	STAFF_ROOM,
	CEO_OFFICE,
	KENNEL,
	MEAT_ROOM,
}

var moving: bool = false:
	get:
		return moving
	set(new_moving):
		if moving != new_moving:
			moving = new_moving
			moving_changed.emit(moving)

var current_room: Room = Room.LOBBY:
	get:
		return current_room
	set(room):
		if visited_rooms.has(room):
			visited_rooms[room] += 1
		else:
			visited_rooms[room] = 1
		current_room = room
		moving = false
		room_changed.emit(room)

var secret_access: bool = false

var visited_rooms: Dictionary = {}

var last_character: DialogicCharacter = null

func reset_state() -> void:
	print('resetting state')
	print('previously visited rooms: ', visited_rooms)
	moving = false
	current_room = Room.LOBBY
	secret_access = false
	visited_rooms = {}
	last_character = null

func is_first_visit() -> bool:
	return visited_rooms[current_room] == 1

func get_transitions(from: Room = current_room) -> Array:
	return {
		Room.LOBBY:
		[
			Room.TOILET,
			Room.GROOMING,
		],
		Room.TOILET: [
			Room.LOBBY,
			Room.GROOMING,
		],
		Room.GROOMING:
		[
			Room.LOBBY,
			Room.SUPPLY_ROOM,
			Room.CORRIDOR,
		],
		Room.CORRIDOR:
		[
			Room.GROOMING,
			Room.SUPPLY_ROOM,
			Room.CEO_OFFICE,
			Room.STAFF_ROOM,
			Room.KENNEL,
		],
		Room.SUPPLY_ROOM: [Room.CORRIDOR],
		Room.STAFF_ROOM: [Room.CORRIDOR],
		Room.CEO_OFFICE: [Room.CORRIDOR],
		Room.KENNEL: [Room.CORRIDOR, Room.MEAT_ROOM] if secret_access else [Room.CORRIDOR],
		Room.MEAT_ROOM: [Room.KENNEL],
	}[from]


func get_room_name(room: Room = current_room) -> String:
	return {
		Room.LOBBY: "Lobby",
		Room.TOILET: "Restroom",
		Room.GROOMING: "Grooming Room",
		Room.CORRIDOR: "Corridor",
		Room.SUPPLY_ROOM: "Supply Room",
		Room.STAFF_ROOM: "Staff Room",
		Room.CEO_OFFICE: "CEO's Office",
		Room.KENNEL: "Kennel",
		Room.MEAT_ROOM: "Meat Room",
	}[room]

func dialogic_default_action():
	var new_event = InputEventAction.new()
	new_event.action = "dialogic_default_action"
	new_event.pressed = true
	Input.parse_input_event(new_event)

func get_room_timeline_id(room: Room) -> String:
	return "res://story/arrival_" + {
		Room.LOBBY: "lobby",
		Room.TOILET: "toilet",
		Room.GROOMING: "grooming",
		Room.CORRIDOR: "corridor",
		Room.SUPPLY_ROOM: "supply_room",
		Room.STAFF_ROOM: "staff_room",
		Room.CEO_OFFICE: "ceo_office",
		Room.KENNEL: "kennel",
		Room.MEAT_ROOM: "meat_room",
	}[room] + ".dtl"

func get_memory_timeline_id(character_id: String, memory_id: String) -> String:
	var timeline_id = ""
	# TODO
	return "res://story/" + timeline_id + ".dtl"

func move_to_room(room: Room):
	moving = true
	var events = Dialogic.current_timeline_events
	var has_bye = events.any(
		func(event: DialogicEvent): return event is DialogicLabelEvent and event.name == "bye"
	)
	if has_bye:
		Dialogic.Jump.jump_to_label('bye')
		dialogic_default_action()
		await Dialogic.timeline_ended
	Dialogic.start_timeline(get_room_timeline_id(room))
	current_room = room

func _ready():
	Dialogic.event_handled.connect(Callable(self, "_on_event_handled"))

func _on_event_handled(event: DialogicEvent):
	if event is DialogicCharacterEvent:
		last_character = event.character
	if event is DialogicTextEvent and event.character:
		last_character = event.character

func select_memory(memory_id: String):
	Dialogic.start_timeline(get_memory_timeline_id(last_character.get_character_name(), memory_id))
