extends Node
class_name InventoryHandler

@export var PlayerBody : CharacterBody3D
@export_flags_3d_physics var CollisionMask : int
@export var ItemSlotsCount : int = 8
@export var InventoryGrid : GridContainer
@export var InventorySlotPrefab : PackedScene = preload("res://Interacao/Player/InventorySlot.tscn")
@export var HandMount: Node3D

var CardReaderUI : Control = null 
var InventorySlots : Array[InventorySlot] = []
var selected_slot : int = -1
var current_held_item: Node3D = null

const HELD_ITEM_COLLISION_LAYER = 1 << 29

const CAMINHO_LANTERNA_DESCARREGADA = "res://Interacao/Inventario/Itens_interagiveis/Lanterna/lanterna.tscn"
const CAMINHO_LANTERNA_CARREGADA = "res://Interacao/Inventario/Itens_interagiveis/Lanterna/lanterna.tscn"
const CAMINHO_PILHA = "res://Interacao/Inventario/Itens_interagiveis/Pilha/pilha.tscn"
const CAMINHO_CHAVE = "res://Interacao/Inventario/Itens_interagiveis/Chave/chave.tscn"
const CAMINHO_PECA_TORNEIRA = "res://Interacao/Inventario/Itens_interagiveis/Peca_torneira/peca_torneira.tscn"
const CAMINHOS_CARTAS = [
	"res://Interacao/Inventario/Itens_interagiveis/Carta/carta.tscn",
	"res://Interacao/Inventario/Itens_interagiveis/Carta/carta2.tscn",
    "res://Interacao/Inventario/Itens_interagiveis/Carta/carta3.tscn"
]

func _ready() -> void:
	CardReaderUI = get_parent().get_node_or_null("CardReaderUI")
	
	for i in range(ItemSlotsCount):
		var slot = InventorySlotPrefab.instantiate() as InventorySlot
		if InventoryGrid:
			InventoryGrid.add_child(slot)
		else:
			return
			
		slot.InventorySlotID = i
		slot.OnItemDropped.connect(ItemDroppedOnSlot.bind())
		InventorySlots.append(slot)
		
	if CardReaderUI:
		CardReaderUI.visible = false

func PickupItem(item : ItemData):
	for slot in InventorySlots:
		if not slot.SlotFilled:
			slot.FillSlot(item)
			break

func ItemDroppedOnSlot(fromSlotID : int, toSlotID : int):
	var fromSlot = InventorySlots[fromSlotID]
	var toSlot = InventorySlots[toSlotID]
	
	var fromItem = fromSlot.SlotData
	var toItem = toSlot.SlotData
	
	if fromItem and toItem:
		var from_path = fromItem.ItemModelPrefab.resource_path
		var to_path = toItem.ItemModelPrefab.resource_path
		
		var is_combination = false
		
		if from_path == CAMINHO_PILHA and to_path == CAMINHO_LANTERNA_DESCARREGADA:
			var LanternaCarregadaData = _load_item_data_by_path(CAMINHO_LANTERNA_CARREGADA)
			if LanternaCarregadaData:
				toSlot.FillSlot(LanternaCarregadaData)
				fromSlot.FillSlot(null)
				is_combination = true
		
		elif from_path == CAMINHO_LANTERNA_DESCARREGADA and to_path == CAMINHO_PILHA:
			var LanternaCarregadaData = _load_item_data_by_path(CAMINHO_LANTERNA_CARREGADA)
			if LanternaCarregadaData:
				fromSlot.FillSlot(LanternaCarregadaData)
				toSlot.FillSlot(null)
				is_combination = true
		
		if is_combination:
			if toSlotID == selected_slot or fromSlotID == selected_slot:
				_clear_held_item()
				_show_selected_item()
			return
	
	toSlot.FillSlot(fromItem)
	fromSlot.FillSlot(toItem)

func _load_item_data_by_path(path_do_modelo: String) -> ItemData:
	var player_interaction_handler = get_parent().get_node_or_null("PlayerInteractionHandler")
	if player_interaction_handler:
		for item_data in player_interaction_handler.ItemTypes:
			if item_data and item_data.ItemModelPrefab and item_data.ItemModelPrefab.resource_path == path_do_modelo:
				return item_data
	
	return null

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data["Type"] == "Item"

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var newItem = InventorySlots[data["ID"]].SlotData.ItemModelPrefab.instantiate() as Node3D
	InventorySlots[data["ID"]].FillSlot(null)
	PlayerBody.get_parent().add_child(newItem)
	newItem.global_position = GetWorldMousePosition()

func GetWorldMousePosition() -> Vector3:
	var mousePos = get_viewport().get_mouse_position()
	var cam = get_viewport().get_camera_3d()
	var ray_start = cam.project_ray_origin(mousePos)
	var ray_end = ray_start + cam.project_ray_normal(mousePos) * cam.global_position.distance_to(PlayerBody.global_position) * 2
	var world3d : World3D = PlayerBody.get_world_3d()
	var space_state = world3d.direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, CollisionMask)
	var results = space_state.intersect_ray(query)

	if results:
		return results["position"] + Vector3(0, 0.5, 0)
	else:
		return ray_start.lerp(ray_end, 0.5) + Vector3(0, 0.5, 0)

func SelectSlot(id: int):
	if id < 0 or id >= InventorySlots.size():
		return
		
	_clear_held_item()
		
	if selected_slot != -1:
		InventorySlots[selected_slot].SetSelected(false)
		
	selected_slot = id
	InventorySlots[selected_slot].SetSelected(true)
	
	_show_selected_item()

func _clear_held_item():
	if is_instance_valid(current_held_item):
		current_held_item.queue_free()
		current_held_item = null

func _show_selected_item():
	if selected_slot == -1:
		return
		
	var slot = InventorySlots[selected_slot]
	
	if slot.SlotFilled and slot.SlotData.ItemModelPrefab:
		var item_model = slot.SlotData.ItemModelPrefab.instantiate() as Node3D
		current_held_item = item_model
		
		for child in item_model.get_children():
			if child is CollisionObject3D:
				var body = child as CollisionObject3D
				body.set_collision_layer(HELD_ITEM_COLLISION_LAYER)
				body.set_collision_mask(0) 
				break
		
		if is_instance_valid(HandMount):
			HandMount.add_child(item_model)
		else:
			printerr("ERRO: O nó HandMount não está configurado.")

func _input(event):
	var handled = false
	
	if CardReaderUI and CardReaderUI.visible:
		if event.is_action_pressed("ui_cancel"):
			CardReaderUI.visible = false
			get_viewport().set_input_as_handled()
			handled = true
		return

	if event.is_action_pressed("slot_1"):
		SelectSlot(0)
		handled = true
	elif event.is_action_pressed("slot_2"):
		SelectSlot(1)
		handled = true
	elif event.is_action_pressed("slot_3"):
		SelectSlot(2)
		handled = true
	elif event.is_action_pressed("slot_4"):
		SelectSlot(3)
		handled = true
	elif event.is_action_pressed("slot_5"):
		SelectSlot(4)
		handled = true
	elif event.is_action_pressed("slot_6"):
		SelectSlot(5)
		handled = true
	elif event.is_action_pressed("slot_7"):
		SelectSlot(6)
		handled = true
	elif event.is_action_pressed("slot_8"):
		SelectSlot(7)
		handled = true
	
	elif event.is_action_pressed("drop_item"):
		DropSelectedItem()
		handled = true
		
	if handled:
		get_viewport().set_input_as_handled()

func DropSelectedItem():
	if selected_slot == -1:
		return
	var slot := InventorySlots[selected_slot]
	if not slot.SlotFilled:
		return
	_clear_held_item()
	var newItem = slot.SlotData.ItemModelPrefab.instantiate() as Node3D
	slot.FillSlot(null)
	PlayerBody.get_parent().add_child(newItem)
	newItem.global_position = GetWorldMousePosition()

func ConsumeSelectedItem():
	if selected_slot != -1:
		_clear_held_item()
		InventorySlots[selected_slot].FillSlot(null)

func is_key_selected() -> bool:
	if selected_slot == -1:
		return false
		
	var selected_item_slot: InventorySlot = InventorySlots[selected_slot]
	
	if selected_item_slot.SlotFilled:
		if selected_item_slot.SlotData.ItemModelPrefab:
			if selected_item_slot.SlotData.ItemModelPrefab.resource_path == CAMINHO_CHAVE:
				return true
			
	return false

func is_faucet_part_selected() -> bool:
	if selected_slot == -1:
		return false
		
	var selected_item_slot: InventorySlot = InventorySlots[selected_slot]
	
	if selected_item_slot.SlotFilled:
		if selected_item_slot.SlotData.ItemModelPrefab:
			if selected_item_slot.SlotData.ItemModelPrefab.resource_path == CAMINHO_PECA_TORNEIRA:
				return true
			
	return false

func is_card_selected() -> bool:
	if selected_slot == -1:
		return false
		
	var selected_item_slot: InventorySlot = InventorySlots[selected_slot]
	
	if selected_item_slot.SlotFilled:
		if selected_item_slot.SlotData.ItemModelPrefab:
			var item_path = selected_item_slot.SlotData.ItemModelPrefab.resource_path
			if item_path in CAMINHOS_CARTAS:
				return true
			
	return false

func get_selected_item_data() -> ItemData:
	if selected_slot != -1:
		return InventorySlots[selected_slot].SlotData
	return null

func OpenCardReaderUI(card_data: ItemData):
	var card_content_label: Label = null
	if CardReaderUI:
		card_content_label = CardReaderUI.get_node_or_null("Panel/CardContentLabel")
	
	if card_content_label:
		var card_item_data: CardItemData = card_data as CardItemData
		
		if card_item_data:
			card_content_label.text = card_item_data.get_card_text()
			CardReaderUI.visible = true
		else:
			printerr("ERRO: O ItemData selecionado não é um CardItemData válido.")
	else:
		printerr("ERRO: CardReaderUI ou CardContentLabel não encontrado. Verifique os nomes dos nós.")
