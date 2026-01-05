extends Node3D
class_name InteractableItem

# Iluminar item --------
@onready var highlight_mesh = $Modelo/ItemHighlightMesh

func GainFocus():
	if highlight_mesh:
		highlight_mesh.visible = true

func LoseFocus():
	if highlight_mesh:
		highlight_mesh.visible = false
# ----------------------
