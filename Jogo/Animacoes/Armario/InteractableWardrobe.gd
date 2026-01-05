extends Node3D
class_name InteractableWardrobe

# Abrir/Fechar porta ----------
@onready var animation_player: AnimationPlayer = $"AnimationPlayer"
# --- Novo: nó de áudio 3D para o som da porta ---
@onready var door_sound: AudioStreamPlayer3D = $"DoorSound"
# -----------------------------------------------------------------
var porta_fechada = true
var proximidade = false

func Interagir():
	if porta_fechada:
		porta_fechada = false
		animation_player.play("abrir_porta")
		# --- Toca som ao abrir ---
		if is_instance_valid(door_sound):
			door_sound.play()
	else:
		if proximidade == false:
			porta_fechada = true
			animation_player.play("fechar_porta")
# ----------------------
