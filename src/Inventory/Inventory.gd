extends Control

const INFO_OFFSET: Vector2 = Vector2(20, 0)

var item_to_delete: InventoryItem = null
var item_to_delete_position: Vector2i = Vector2i.ZERO

var can_edit: bool = true:
	set(new_can_edit):
		can_edit = new_can_edit
		ctrl_inventory_left.can_edit = can_edit
		ctrl_inventory_right.can_edit = can_edit

@onready
var ctrl_inventory_left: CtrlInventoryGrid = $VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer/CtrlInventoryGridLeft
@onready
var ctrl_inventory_right: CtrlInventoryGrid = $VBoxContainer/HBoxContainer/VBoxContainer2/PanelContainer2/CtrlInventoryGridRight
@onready var lbl_info: Label = $LblInfo
@onready var lbl_description: Label = $%LabelDescription
@onready var inventory_left: InventoryGrid = $InventoryGridLeft
@onready var inventory: InventoryGrid = $InventoryGridRight
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog


func _ready() -> void:
	ctrl_inventory_left.item_mouse_entered.connect(Callable(self, "_on_item_mouse_entered"))
	ctrl_inventory_left.item_mouse_exited.connect(Callable(self, "_on_item_mouse_exited"))
	inventory_left.item_added.connect(Callable(self, "_on_item_added_left"))
	ctrl_inventory_right.item_mouse_entered.connect(Callable(self, "_on_item_mouse_entered"))
	ctrl_inventory_right.item_mouse_exited.connect(Callable(self, "_on_item_mouse_exited"))
	ctrl_inventory_right.item_dropped.connect(Callable(self, "_on_item_dropped"))
	ctrl_inventory_right.inventory_item_activated.connect(Callable(self, "_on_item_activated"))
	confirmation_dialog.canceled.connect(Callable(self, "_on_delete_cancel"))
	confirmation_dialog.confirmed.connect(Callable(self, "_on_delete_confirm"))
	inventory.item_removed.connect(Callable(self, "_on_item_removed"))
	inventory.item_added.connect(Callable(self, "_on_item_added"))
	Memories.memory_added.connect(Callable(self, "_on_memory_added"))

	Memories.add_memory('test')

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
		lbl_description.set_text(item.get_property("description"))
		lbl_description.show()
		#lbl_info.show()
		#lbl_info.set_global_position(get_global_mouse_position() + INFO_OFFSET)
	else:
		lbl_description.hide()
		#lbl_info.hide()


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
	print_debug("activated", item)


func _on_item_added_left(item: InventoryItem) -> void:
	# var pos = inventory.find_free_place(item)
	# inventory_left.transfer(item, inventory)
	# print('pos', item_to_delete_position)
	# print(pos.success, pos.position)
	# TODO: investigate why this does not work
	# to reproduce: move item from inventory to left inventory
	# inventory.move_item_to(item, item_to_delete_position)
	# if pos.success:
	# 	inventory.move_item_to(item, pos.position)
	pass


func _on_memory_added(memory: Dictionary) -> void:
	var short_title = memory.short_title
	if short_title == null or short_title.length() == 0:
		short_title = memory.title
	add_item(memory.id, memory.title, memory.width, memory.height, memory.description, short_title)


func add_item(id: String, title: String, width = 1, height = 1, description = "", short_title = ""):
	var protoset: ItemProtoset = inventory_left.item_protoset
	var item: InventoryItem = InventoryItem.new()
	item.protoset = protoset
	item.prototype_id = "base_memory"
	item.set_property("id", id)
	item.set_property("title", title)
	item.set_property("width", width)
	item.set_property("height", height)
	item.set_property("description", description)
	item.set_property("short_title", short_title)
	var pos = inventory_left.find_free_place(item)
	if pos.success:
		inventory_left.add_item_at(item, pos.position)
	else:
		pos = inventory.find_free_place(item)
		if pos.success:
			inventory.add_item_at(item, pos.position)
	inventory_left.sort()

func _on_item_removed(item: InventoryItem) -> void:
	var id = item.get_property("id", "")
	Memories.remove_active_memory(id)

func _on_item_added(item: InventoryItem) -> void:
	var id = item.get_property("id", "")
	Memories.add_active_memory(id)
