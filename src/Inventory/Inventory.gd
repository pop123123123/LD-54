extends Control

const info_offset: Vector2 = Vector2(20, 0)

@onready var ctrl_inventory_left: CtrlInventoryGrid = $VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer/CtrlInventoryGridLeft
@onready var ctrl_inventory_right: CtrlInventoryGrid = $VBoxContainer/HBoxContainer/VBoxContainer2/PanelContainer2/CtrlInventoryGridRight
@onready var lbl_info: Label = $LblInfo
@onready var inventory_left: InventoryGrid = $InventoryGridLeft
@onready var inventory: InventoryGrid = $InventoryGridRight
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog

var item_to_delete: InventoryItem = null
var item_to_delete_position: Vector2i = Vector2i.ZERO


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


func _on_item_mouse_entered(item: InventoryItem) -> void:
	lbl_info.show()
	lbl_info.text = item.prototype_id
	if item_to_delete == null:
		print(item)
		item_to_delete_position = inventory.get_item_position(item)
		print(item_to_delete_position)



func _on_item_mouse_exited(_item: InventoryItem) -> void:
	lbl_info.hide()


func _input(event: InputEvent) -> void:
	if !(event is InputEventMouseMotion):
		return

	lbl_info.set_global_position(get_global_mouse_position() + info_offset)

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
	print_debug('activated', item)

func _on_item_added_left(item: InventoryItem) -> void:
	print_debug('added', item)
	# var pos = inventory.find_free_place(item)
	inventory_left.transfer(item, inventory)
	# print('pos', item_to_delete_position)
	# print(pos.success, pos.position)
	# TODO: investigate why this does not work
	# to reproduce: move item from inventory to left inventory
	inventory.move_item_to(item, item_to_delete_position)
	# if pos.success:
	# 	inventory.move_item_to(item, pos.position)

