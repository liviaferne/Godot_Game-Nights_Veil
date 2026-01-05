extends Node3D
class_name InteractableChest

signal item_consumido # Novo sinal para notificar o PlayerInteractionHandler

@onready var animation_player: AnimationPlayer = $"AnimationPlayer"
@onready var label: Label = $"label/Label"
# --- Novo: AudioStreamPlayer3D para o som do baú ---
@onready var bau_player: AudioStreamPlayer3D = $"BauSound"
# -----------------------------------------------------------------
@export var precisa_de_chave: bool = true

var bau_fechado: bool = true
var aguardando_abertura: bool = false

func Interagir(player_pode_abrir: bool) -> void:
	if not bau_fechado:
		return
		
	if precisa_de_chave and not player_pode_abrir:
		aguardando_abertura = false
		label.text = "Precisa da chave selecionada!"
		get_tree().create_timer(2.0).timeout.connect(func():    
			if is_instance_valid(label) and label.text == "Precisa da chave selecionada!":
				label.text = "Aperte [F] para interagir"
		)
		return
		
	aguardando_abertura = true
	label.text = "Aperte [R] para abrir!"

func Abrir() -> void:
	if not bau_fechado or not aguardando_abertura:
		return
		
	bau_fechado = false
	aguardando_abertura = false
	animation_player.play("abrir_bau")
	# --- Toca som do baú ---
	if is_instance_valid(bau_player):
		bau_player.play()
	label.text = ""
	
	if precisa_de_chave:
		item_consumido.emit() # Emite o sinal para remover a chave

func ResetarInteracao():
	aguardando_abertura = false
