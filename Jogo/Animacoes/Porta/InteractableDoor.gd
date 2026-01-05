extends Node3D
class_name InteractableDoor

# Abrir/Fechar porta ----------
@onready var animation_player: AnimationPlayer = $"AnimationPlayer"
@onready var door_sound: AudioStreamPlayer3D = $"DoorSound"  # nó de áudio 3D filho da porta
var porta_fechada = true

func Interagir():
	if porta_fechada:
		porta_fechada = false
		animation_player.play("abrir_porta")
		if is_instance_valid(door_sound):
			door_sound.play()  # toca som ao abrir
	else:
		porta_fechada = true
		animation_player.play("fechar_porta")
		if is_instance_valid(door_sound):
			door_sound.play()  # toca som ao fechar
# ----------------------
