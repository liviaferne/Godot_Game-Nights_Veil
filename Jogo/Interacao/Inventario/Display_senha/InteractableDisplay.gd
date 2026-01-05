extends Node3D
class_name InteractableDisplay

@onready var number_on_screen: Label3D = $Tela/Senha
@onready var beep_player: AudioStreamPlayer = $BeepPlayer  # <-- adicionado nó AudioStreamPlayer

# Para liberar mouse
var interacted: bool = false

var display_list: Array = []  
var senha_correta: Array = [8, 5, 6, 2, 1]

var player_ref = null

# Liberar display ---------------------------------
func digitar_senha(player):
	player_ref = player
	interacted = true
	
	if player_ref and player_ref.has_method("disable_auto_capture"):
		player_ref.disable_auto_capture()
# -------------------------------------------------

# Adicionar digito --------------------------------
func add_digit(d):
	if not interacted:
		return
	if display_list.size() < 5:
		display_list.append(str(d))
		# Toca o beep sempre que um número é inserido
		if is_instance_valid(beep_player):
			beep_player.play()
# -------------------------------------------------

# Limpar display ----------------------------------
func clear_display():
	if not interacted:
		return
	display_list.clear()
# -------------------------------------------------

# Botao submit ------------------------------------
func submit():
	var senha_digitada = []
	for s in display_list:
		senha_digitada.append(int(s))
	if senha_digitada == senha_correta:
		display_list = ["O", "K"]
		await get_tree().create_timer(1).timeout
		stop_interaction()
		await get_tree().create_timer(0.8).timeout
		get_tree().change_scene_to_file("res://Interacao/Menu/escapou.tscn")
	else:
		display_list = ["E", "R", "R"]
		await get_tree().create_timer(0.8).timeout
		display_list.clear()
# -------------------------------------------------

# Exibir no display -------------------------------
func _physics_process(_delta: float) -> void:
	if interacted:
		number_on_screen.text = " ".join(display_list)
# -------------------------------------------------

# Parar interacao ---------------------------------
func stop_interaction():
	interacted = false
	display_list.clear()

	player_ref.enable_auto_capture()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	player_ref = null
# -------------------------------------------------
