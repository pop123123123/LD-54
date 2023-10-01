extends Node

signal room_changed(room: Room)

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

var current_room: Room = Room.LOBBY:
	get:
		return current_room
	set(room):
		current_room = room
		room_changed.emit(room)

var secret_access: bool = false


func get_transitions(from: Room):
	return {
		Room.LOBBY:
		[
			Room.TOILET,
			Room.GROOMING,
		],
		Room.TOILET: [Room.GROOMING],
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


func get_room_name(room: Room):
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
