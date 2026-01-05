extends StaticBody3D

# Procura o display a partir de botao
func _get_display_from_node(node: Node) -> InteractableDisplay:
	var current = node
	while current:
		if current is InteractableDisplay:
			return current
		current = current.get_parent()
	return null

func _input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Pega o texto dos botoes
		var label: Label3D = get_node("../Label3D")
		var texto = label.text

		# Buscar o display
		var display = _get_display_from_node(self)
		if not display:
			return

		# Digitos
		if texto.is_valid_int():
			display.add_digit(int(texto))
			return
		# Clear
		if texto == "C":
			display.clear_display()
		# Submit
		if texto == "<":
			display.submit()
