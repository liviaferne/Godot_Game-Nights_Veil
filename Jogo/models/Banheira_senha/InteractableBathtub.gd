extends Node3D
class_name InteractableBathtub

signal item_consumido # Novo sinal para notificar o PlayerInteractionHandler

const PECAS_TORNEIRA_PATH = "res://Interacao/Inventario/Itens_interagiveis/Peca_torneira/peca_torneira.tscn"

@onready var agua_node: Node3D = $Agua
@onready var label: Label = $"label/Label"
# --- ALTERADO: AudioStreamPlayer3D para efeito 3D de distância ---
@onready var agua_player: AudioStreamPlayer3D = $Agua/AguaPlayer
# -----------------------------------------------------------------
@export var precisa_de_peca: bool = true

var agua_invisivel: bool = false
var aguardando_interacao: bool = false

func _ready():
	if not is_instance_valid(agua_node):
		printerr("ERRO: O nó 'Agua' (Node3D) não foi encontrado como filho. Verifique a estrutura da cena.")
	# Toca o som da água se estiver visível no início
	if is_instance_valid(agua_node) and is_instance_valid(agua_player):
		if agua_node.visible and not agua_invisivel:
			agua_player.play()
		else:
			if agua_player.playing:
				agua_player.stop()

func Interagir(player_pode_interagir: bool) -> void:
	if agua_invisivel:
		return
		
	if precisa_de_peca and not player_pode_interagir:
		aguardando_interacao = false
		label.text = "Precisa da peça da torneira selecionada!"
		get_tree().create_timer(2.0).timeout.connect(func(): 
			if is_instance_valid(label) and label.text == "Precisa da peça da torneira selecionada!":
				label.text = "Aperte [F] para interagir"
		)
		return
		
	aguardando_interacao = true
	label.text = "Aperte [R] para fechar a água!"

func FecharAgua() -> void:
	if agua_invisivel or not aguardando_interacao:
		return
		
	if is_instance_valid(agua_node):
		agua_node.visible = false 
		agua_invisivel = true
		aguardando_interacao = false
		label.text = "A água foi fechada."
		# Para o som da água quando fechada
		if is_instance_valid(agua_player) and agua_player.playing:
			agua_player.stop()
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(label) and label.text == "A água foi fechada.":
				label.text = ""
		)
		if precisa_de_peca:
			item_consumido.emit() # Emite o sinal para remover a peça
	else:
		label.text = "Erro: Nó 'Agua' não encontrado."

func ResetarInteracao():
	aguardando_interacao = false
	if is_instance_valid(label) and not agua_invisivel:
		label.text = "Aperte [F] para interagir"

# --- FUNÇÃO OPCIONAL: Abrir água e tocar som 3D ---
func AbrirAgua():
	if is_instance_valid(agua_node):
		agua_node.visible = true
		agua_invisivel = false
		if is_instance_valid(agua_player):
			agua_player.play()
		aguardando_interacao = true
		if is_instance_valid(label):
			label.text = "Aperte [R] para fechar a água"
