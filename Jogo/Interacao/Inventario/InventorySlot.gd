extends Control
class_name InventorySlot

signal OnItemDropped(fromSlotID, toSlotID)

@export var IconSlot : TextureRect

var InventorySlotID : int = -1
var SlotFilled : bool = false
var SlotData : ItemData
var is_selected := false

func FillSlot(data : ItemData):
	SlotData = data
	if SlotData != null:
		SlotFilled = true
		IconSlot.texture = data.Icon
	else:
		SlotFilled = false
		IconSlot.texture = null

# ⭐ NOVO: BLOQUEIA NAVEGAÇÃO DE FOCO POR A/D (ui_left/ui_right) ⭐
func _gui_input(event):
	# Verifica se o evento é um pressionamento de A (ui_left) ou D (ui_right)
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		# Consome o evento para impedir que o Godot mude o foco do slot
		get_viewport().set_input_as_handled()
		
func _get_drag_data(at_position: Vector2) -> Variant:
	if SlotFilled:
		var preview : TextureRect = TextureRect.new()
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size = IconSlot.size
		preview.pivot_offset = IconSlot.size / 2.0
		preview.rotation = 2.0
		preview.texture = IconSlot.texture
		set_drag_preview(preview)
		return {"Type": "Item", "ID": InventorySlotID}
	else:
		return false

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data["Type"] == "Item"

func _drop_data(at_position: Vector2, data: Variant) -> void:
	OnItemDropped.emit(data["ID"], InventorySlotID)

func SetSelected(value: bool):
	is_selected = value
	if value:
		modulate = Color(1, 1, 0.6)
	else:
		modulate = Color(1, 1, 1)
