extends Node

signal OnItemPickedUp(item)

@export var ItemTypes : Array[ItemData] = []

var NearbyBodies : Array[InteractableItem] = []

@onready var interaction_area = $"../InteractionArea"
@onready var inventory_handler = null
@onready var camera = get_parent().get_node("Head/Camera3D")
@onready var seecast = camera.get_node("SeeCast")
@onready var floating_hint_label = $"../InventoryUI/FloatingHintLabel"

func _ready() -> void:
	var inventory_ui_node = get_node_or_null("../InventoryUI")
	if inventory_ui_node and inventory_ui_node.has_method("is_key_selected"):
		inventory_handler = inventory_ui_node
		if not self.OnItemPickedUp.is_connected(inventory_handler.PickupItem):
			self.OnItemPickedUp.connect(inventory_handler.PickupItem)
	elif inventory_ui_node == null:
		printerr("ERRO: Nó InventoryUI não encontrado no caminho '../InventoryUI'. Verifique a estrutura da cena.")
	else:
		printerr("ERRO: O script InventoryHandler (com a função is_key_selected) não está anexado ao nó InventoryUI.")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interagir"):
		if HandleReadCard():
			return
		HandleFurnitureInteraction()
	if event.is_action_pressed("Interact"):
		HandleItemPickup()
	if event.is_action_pressed("Abrir"):
		Open()
	if event.is_action_pressed("Senha"):
		use_Display()
	if event.is_action_pressed("ui_cancel"):
		close_Display()

func HandleReadCard() -> bool:
	if inventory_handler and inventory_handler.is_card_selected():
		var card_data = inventory_handler.get_selected_item_data()
		if card_data:
			inventory_handler.OpenCardReaderUI(card_data)
			return true
	return false

func HandleFurnitureInteraction():
	for body in interaction_area.get_overlapping_bodies():
		var chest = body.get_parent() as InteractableChest
		var bathtub = body.get_parent() as InteractableBathtub
		
		if chest and chest.bau_fechado:
			if is_furniture_in_front(chest):
				if inventory_handler:
					var player_pode_abrir = inventory_handler.is_key_selected()
					
					if not chest.item_consumido.is_connected(inventory_handler.ConsumeSelectedItem):
						chest.item_consumido.connect(inventory_handler.ConsumeSelectedItem)
						
					chest.Interagir(player_pode_abrir)
					return
		
		if bathtub and not bathtub.agua_invisivel:
			if is_furniture_in_front(bathtub):
				if inventory_handler:
					var player_pode_interagir = inventory_handler.is_faucet_part_selected()
					
					if not bathtub.item_consumido.is_connected(inventory_handler.ConsumeSelectedItem):
						bathtub.item_consumido.connect(inventory_handler.ConsumeSelectedItem)
						
					bathtub.Interagir(player_pode_interagir)
					return

func HandleItemPickup():
	# 1. Tenta pegar item via RayCast (Prioridade)
	if _handle_pickup_from_raycast():
		return
		
	# 2. Lógica original para pegar o item mais próximo detectado pela Area3D.
	var nearestItem : InteractableItem = null
	var nearestItemDistance : float = INF
	var player_pos = get_parent().global_position
	
	for item in NearbyBodies:
		var d = item.global_position.distance_to(player_pos)
		if d < nearestItemDistance:
			nearestItemDistance = d
			nearestItem = item
			
	if nearestItem != null:
		if not _is_item_blocked_by_furniture(nearestItem):
			_handle_item_pickup(nearestItem)
			return

func _handle_pickup_from_raycast() -> bool:
	if not is_instance_valid(seecast) or not seecast.is_colliding():
		return false

	var collider = seecast.get_collider()
	var item_node = get_interactable_from_node(collider)
	
	if item_node and item_node is InteractableItem:
		if not _is_item_blocked_by_furniture(item_node):
			_handle_item_pickup(item_node)
			return true
		
	return false

func _handle_item_pickup(item):
	item.queue_free()
	NearbyBodies.erase(item) 
	var itemPrefab = item.scene_file_path

	for i in range(ItemTypes.size()):
		if ItemTypes[i].ItemModelPrefab != null \
		and ItemTypes[i].ItemModelPrefab.resource_path == itemPrefab:
			OnItemPickedUp.emit(ItemTypes[i])    
			return

func Open():
	for body in interaction_area.get_overlapping_bodies():
		var chest = body.get_parent() as InteractableChest
		var bathtub = body.get_parent() as InteractableBathtub
		var door = body.get_parent() as InteractableDoor
		var desk = body.get_parent() as InteractableDesk
		var wardrobe = body.get_parent() as InteractableWardrobe

		if chest and chest.aguardando_abertura:
			chest.Abrir()
			return
			
		if bathtub and bathtub.aguardando_interacao:
			bathtub.FecharAgua()
			return
		
		if door:
			door.Interagir()
			return
			
		if desk:
			desk.Interagir()
			return
			
		if wardrobe:
			wardrobe.Interagir()
			return
			
		if chest and chest.bau_fechado == true:
			chest.Interagir(false)
			return

func _on_interaction_area_body_entered(body: Node3D) -> void:
	var interactable_item = get_interactable_from_node(body)
	var label: Label = null
	
	if not interactable_item:
		_labels_in(body, label)
		return

	# Restrição de item segurado removida daqui para permitir a exibição da dica
	# mesmo com item na mão. O filtro de colisão deve resolver o problema de pegar o próprio item.

	var movel_aberto = true
	var max_distance = 2.0

	for b in interaction_area.get_overlapping_bodies():
		var chest = b.get_parent() as InteractableChest
		if chest and chest.bau_fechado:
			if chest.global_position.distance_to(interactable_item.global_position) < max_distance:
				movel_aberto = false
				break
		var desk = b.get_parent() as InteractableDesk
		if desk and desk.porta_fechada:
			if desk.global_position.distance_to(interactable_item.global_position) < max_distance:
				movel_aberto = false
				break
		var wardrobe = b.get_parent() as InteractableWardrobe
		if wardrobe and wardrobe.porta_fechada:
			if wardrobe.global_position.distance_to(interactable_item.global_position) < max_distance:
				movel_aberto = false
				break

	if not movel_aberto:
		return

	if is_item_in_front(interactable_item):
		_remove_furniture_labels()
		interactable_item.GainFocus()
		if not NearbyBodies.has(interactable_item):
			NearbyBodies.append(interactable_item)
		label = interactable_item.get_node("label/Label")
		label.text = "Aperte [E] para pegar"

func _labels_in(body, label):
	var door = body.get_parent() as InteractableDoor
	var chest = body.get_parent() as InteractableChest
	var desk = body.get_parent() as InteractableDesk
	var wardrobe = body.get_parent() as InteractableWardrobe
	var bathtub = body.get_parent() as InteractableBathtub
	
	var movel_simples_r = false
	var movel_complexo_f = false

	if inventory_handler and inventory_handler.is_card_selected():
		if floating_hint_label:
			floating_hint_label.text = "Aperte [F] para ler"
			floating_hint_label.visible = true
		return

	if floating_hint_label:
		floating_hint_label.visible = false
	
	if door and is_furniture_in_front(door):
		label = door.get_node("label/Label")
		movel_simples_r = true
		
	elif desk and is_furniture_in_front(desk):
		label = desk.get_node("label/Label")
		movel_simples_r = true
		
	elif wardrobe and is_furniture_in_front(wardrobe):
		label = wardrobe.get_node("label/Label")
		movel_simples_r = true
		
	elif chest and chest.bau_fechado==true and is_furniture_in_front(chest):
		label = chest.get_node("label/Label")
		movel_complexo_f = true
		
	elif bathtub and is_furniture_in_front(bathtub) and not bathtub.agua_invisivel:
		label = bathtub.get_node("label/Label")
		movel_complexo_f = true
		
	var display = body.get_parent() as InteractableDisplay
	if display:
		if is_item_in_front(display):
			label = display.get_node("label/Label")
			label.text = "Aperte [U] para inserir senha"
		return
		
	if label:
		if movel_simples_r:
			label.text = "Aperte [R] para abrir"
		elif movel_complexo_f:
			label.text = "Aperte [F] para interagir"

func _on_interaction_area_body_exited(body: Node3D) -> void:
	var interactable_item = get_interactable_from_node(body)
	var label: Label = null
	
	var chest = body.get_parent() as InteractableChest
	if chest:
		chest.ResetarInteracao()
		
	var bathtub = body.get_parent() as InteractableBathtub
	if bathtub:
		bathtub.ResetarInteracao()
	
	if not interactable_item:
		_labels_out(body, label)
		return
	
	if interactable_item and NearbyBodies.has(interactable_item):
		interactable_item.LoseFocus()
		NearbyBodies.erase(interactable_item)
		label = interactable_item.get_node("label/Label")
		label.text = ""
		return

func _labels_out(body, label):
	var door = body.get_parent() as InteractableDoor
	if door:
		label = door.get_node("label/Label")
	
	var chest = body.get_parent() as InteractableChest
	if chest:
		label = chest.get_node("label/Label")
		
	var desk = body.get_parent() as InteractableDesk
	if desk:
		label = desk.get_node("label/Label")
		
	var wardrobe = body.get_parent() as InteractableWardrobe
	if wardrobe:
		label = wardrobe.get_node("label/Label")
		
	var bathtub = body.get_parent() as InteractableBathtub
	if bathtub:
		label = bathtub.get_node("label/Label")
		
	var display = body.get_parent() as InteractableDisplay
	if display:
		label = display.get_node("label/Label")
		
	if label:
		label.text = ""
	
	if floating_hint_label:
		floating_hint_label.text = ""
		floating_hint_label.visible = false

func get_interactable_from_node(node: Node) -> InteractableItem:
	var current = node
	while current:
		if current is InteractableItem:
			return current
		current = current.get_parent()
	return null

func _is_item_blocked_by_furniture(item: Node3D) -> bool:
	var max_distance := 2.0

	for b in interaction_area.get_overlapping_bodies():
		var f = b.get_parent()

		if f is InteractableChest and f.bau_fechado:
			if f.global_position.distance_to(item.global_position) < max_distance:
				return true

		if f is InteractableDesk and f.porta_fechada:
			if f.global_position.distance_to(item.global_position) < max_distance:
				return true

		if f is InteractableWardrobe and f.porta_fechada:
			if f.global_position.distance_to(item.global_position) < max_distance:
				return true

	return false

func _show_furniture_label(body):
	var furniture = body.get_parent()
	var label = furniture.get_node_or_null("label/Label")
	if label:
		label.text = "Aperte [R] para interagir"

func _remove_furniture_labels():
	for b in interaction_area.get_overlapping_bodies():
		var furniture = b.get_parent()
		var label = furniture.get_node_or_null("label/Label")
		if label:
			label.text = ""

func is_item_in_front(item: Node3D) -> bool:
	var to_item = (item.global_position - camera.global_position).normalized()
	var forward = -camera.global_transform.basis.z
	var dot = forward.dot(to_item)
	return dot > 0.8

func is_furniture_in_front(item: Node3D) -> bool:
	var to_item = (item.global_position - camera.global_position).normalized()
	var forward = -camera.global_transform.basis.z
	var dot = forward.dot(to_item)
	return dot > 0.5

func use_Display():
	for body in interaction_area.get_overlapping_bodies():
		var display = body.get_parent() as InteractableDisplay
		if display:
			var player_controller = get_parent()
			display.digitar_senha(player_controller)
			var label = display.get_node("label/Label")
			label.text = "[Esc] sair"
			return

func close_Display():
	for body in interaction_area.get_overlapping_bodies():
		var display = body.get_parent() as InteractableDisplay
		if display and display.interacted:
			display.stop_interaction()
