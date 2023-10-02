extends Control

enum Mode {
	VIEW,
	SELECT,
	EDIT,
}

const INFO_OFFSET: Vector2 = Vector2(20, 0)

var item_to_delete: InventoryItem = null
var item_to_delete_position: Vector2i = Vector2i.ZERO

var default_description: String = "":
	set(description):
		default_description = description
		lbl_description.set_text(
			current_description if current_description.length() > 0 else default_description
		)
var current_description: String = "":
	set(description):
		if description != current_description:
			current_description = description
			lbl_description.set_text(
				current_description if current_description.length() > 0 else default_description
			)

var mode: Mode = Mode.VIEW:
	set(new_mode):
		mode = new_mode
		match mode:
			Mode.VIEW:
				can_select = false
				can_edit = false
				default_description = ""
			Mode.SELECT:
				can_select = true
				can_edit = true
				default_description = "Double click on a memory to activate it."
				# inventory_left.clear()
			Mode.EDIT:
				can_select = false
				can_edit = true
				default_description = "You can drag memories around.\nPut a memory away to forget it."

var can_select: bool = false:
	set(new_can_select):
		can_select = new_can_select
		selection_hint.visible = can_select

var can_edit: bool = false:
	set(new_can_edit):
		can_edit = new_can_edit
		ctrl_inventory_left.can_edit = can_edit
		ctrl_inventory_right.can_edit = can_edit

var is_idle: bool = false:
	set(new_is_idle):
		is_idle = new_is_idle
		if is_idle:
			mode = Mode.SELECT
		else:
			mode = Mode.EDIT

@onready var ctrl_inventory_left: CtrlInventoryGrid = %CtrlInventoryGridLeft
@onready var ctrl_inventory_right: CtrlInventoryGrid = %CtrlInventoryGridRight
@onready var lbl_info: Label = $LblInfo
@onready var lbl_description: RichTextLabel = %LabelDescription
@onready var inventory_left: InventoryGrid = $InventoryGridLeft
@onready var inventory: InventoryGrid = $InventoryGridRight
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog
@onready var selection_hint: NinePatchRect = $SelectionHint
@onready var inventory_left_container: Control = %InventoryLeftContainer


func _ready() -> void:
	ctrl_inventory_left.item_mouse_entered.connect(Callable(self, "_on_item_mouse_entered"))
	ctrl_inventory_left.item_mouse_exited.connect(Callable(self, "_on_item_mouse_exited"))
	ctrl_inventory_right.item_mouse_entered.connect(Callable(self, "_on_item_mouse_entered"))
	ctrl_inventory_right.item_mouse_exited.connect(Callable(self, "_on_item_mouse_exited"))
	ctrl_inventory_right.item_dropped.connect(Callable(self, "_on_item_dropped"))
	ctrl_inventory_right.inventory_item_activated.connect(Callable(self, "_on_item_activated"))
	confirmation_dialog.canceled.connect(Callable(self, "_on_delete_cancel"))
	confirmation_dialog.confirmed.connect(Callable(self, "_on_delete_confirm"))
	inventory.item_removed.connect(Callable(self, "_on_item_removed"))
	inventory.item_added.connect(Callable(self, "_on_item_added"))
	inventory_left.contents_changed.connect(Callable(self, "_on_left_contents_changed"))
	_on_left_contents_changed()

	Memories.memory_added.connect(Callable(self, "_on_memory_added"))
	Memories.active_memory_added.connect(Callable(self, "_on_active_memory_added"))

	Dialogic.timeline_started.connect(Callable(self, "_on_timeline_started"))
	_on_timeline_started()
	Dialogic.event_handled.connect(Callable(self, "_on_event_handled"))


func _on_item_mouse_entered(item: InventoryItem) -> void:
	lbl_info.text = item.get_property("title", item.prototype_id)
	if item_to_delete == null:
		item_to_delete_position = inventory.get_item_position(item)


func _on_item_mouse_exited(_item: InventoryItem) -> void:
	pass


func _get_cell_at_mouse_position(ctrl_inventory: CtrlInventoryGrid, inv: Inventory):
	var pos = get_global_mouse_position()
	var rect = ctrl_inventory.get_global_rect()
	var relative_pos = pos - rect.position
	if (
		relative_pos.x < 0
		or relative_pos.y < 0
		or relative_pos.x > rect.size.x
		or relative_pos.y > rect.size.y
	):
		return null
	var normalized_position = relative_pos / rect.size
	var x = floor(normalized_position.x * inv.size.x)
	var y = floor(normalized_position.y * inv.size.y)
	return Vector2i(x, y)


func get_hovered_item():
	var cell = _get_cell_at_mouse_position(ctrl_inventory_left, inventory_left)
	if cell != null:
		return inventory_left.get_item_at(cell)
	cell = _get_cell_at_mouse_position(ctrl_inventory_right, inventory)
	if cell != null:
		return inventory.get_item_at(cell)
	return null


func get_items():
	return inventory.get_items().map(func(item: InventoryItem): return item.get_property("title"))


func _input(event: InputEvent) -> void:
	if !(event is InputEventMouseMotion):
		return

	var item = get_hovered_item()
	if item != null:
		current_description = (
			"[b]" + item.get_property("title", "") + "[/b]\n" + item.get_property("description", "")
		)
	else:
		current_description = ""


func _on_delete_cancel() -> void:
	confirmation_dialog.hide()
	item_to_delete = null


func _on_delete_confirm() -> void:
	inventory.remove_item(item_to_delete)
	confirmation_dialog.hide()


func _on_item_dropped(item_wr: WeakRef, _pos: Vector2) -> void:
	lbl_info.hide()
	var item: InventoryItem = item_wr.get_ref()
	item_to_delete = item
	confirmation_dialog.show()


func _on_item_activated(item: InventoryItem) -> void:
	if mode != Mode.SELECT:
		return
	var id = item.get_property("id", "")
	Globals.select_memory(id)


func _on_memory_added(memory: Dictionary) -> void:
	var item = _create_item(
		memory.id,
		memory.title,
		memory.width,
		memory.height,
		memory.description,
		Memories.get_short_title(memory),
		memory.tile_size,
	)
	add_item(item)


func _on_active_memory_added(memory: Dictionary, x: int, y: int) -> void:
	var item = _create_item(
		memory.id,
		memory.title,
		memory.width,
		memory.height,
		memory.description,
		Memories.get_short_title(memory),
		memory.tile_size,
	)
	add_active_item(item, x, y)


func _create_item(
	id: String, title: String, width = 1, height = 1, description = "", short_title = "", tile_size= "1x1"
) -> InventoryItem:
	var protoset: ItemProtoset = inventory_left.item_protoset
	var item: InventoryItem = InventoryItem.new()
	item.protoset = protoset
	var n = randi() % 2 if tile_size == "1x1" else 0
	item.set_property("id", id)
	item.set_property("title", title)
	item.set_property("width", width)
	item.set_property("height", height)
	item.set_property("image", "res://assets/ui/icons/icon_" + tile_size + "_" + str(n) + ".png")
	item.set_property("description", description)
	item.set_property("short_title", short_title)
	return item


func add_item(item: InventoryItem) -> void:
	var pos = inventory_left.find_free_place(item)
	if pos.success:
		inventory_left.add_item_at(item, pos.position)
	else:
		pos = inventory.find_free_place(item)
		if pos.success:
			inventory.add_item_at(item, pos.position)
	inventory_left.sort()


func add_active_item(item: InventoryItem, x: int, y: int) -> void:
	var res = inventory.add_item_at(item, Vector2i(x, y))
	if not res:
		var pos = inventory.find_free_place(item)
		if pos.success:
			inventory.add_item_at(item, pos.position)
		else:
			add_item(item)


func _on_item_removed(item: InventoryItem) -> void:
	var id = item.get_property("id", "")
	Memories.remove_active_memory(id)


func _on_item_added(item: InventoryItem) -> void:
	var id = item.get_property("id", "")
	var pos = inventory.get_item_position(item)
	Memories.add_active_memory(id, pos.x, pos.y, false)


func _on_timeline_started() -> void:
	# var events = Dialogic.current_timeline_events
	# is_idle = events.any(
	# 	func(event: DialogicEvent): return event is DialogicCommentEvent and event.text == "idle"
	# )
	is_idle = false

func _on_event_handled(event: DialogicEvent):
	if event is DialogicCommentEvent and event.text == "idle":
		is_idle = true

func _on_left_contents_changed() -> void:
	var items: Array = inventory_left.get_items()
	if items.size() > 0:
		inventory_left_container.show()
		if inventory_left.get_items().size() > 0:
			default_description += "\nRemember to save new memories, otherwise they will be forgotten.\n"
	else:
		inventory_left_container.hide()
		mode = mode
